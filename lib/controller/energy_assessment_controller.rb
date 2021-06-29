# frozen_string_literal: true

module Controller
  class EnergyAssessmentController < Controller::BaseController
    get "/api/assessments/search", auth_token_has_all: %w[assessment:search] do
      result =
        if params.key?(:postcode)
          UseCase::FindAssessmentsByPostcode.new.execute(
            params[:postcode],
            params[:assessment_type],
          )
        elsif params.key?(:assessment_id)
          UseCase::FindAssessmentsByAssessmentId.new.execute(
            params[:assessment_id],
          )
        else
          UseCase::FindAssessmentsByStreetNameAndTown.new.execute(
            params[:street_name],
            params[:town],
            params[:assessment_type],
          )
        end

      json_api_response(code: 200, data: result, burrow_key: :assessments)
    rescue StandardError => e
      case e
      when UseCase::FindAssessmentsByStreetNameAndTown::ParameterMissing
        error_response 400, "INVALID_REQUEST", "Required query params missing"
      when UseCase::FindAssessmentsByPostcode::ParameterMissing
        error_response 400, "INVALID_REQUEST", "Required query params missing"
      when UseCase::FindAssessmentsByPostcode::PostcodeNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested postcode is not valid",
        )
      when UseCase::FindAssessmentsByPostcode::AssessmentTypeNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested assessment type is not valid",
        )
      when Helper::RrnHelper::RrnNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested assessment id is not valid",
        )
      else
        server_error(e)
      end
    end

    post "/api/assessments", auth_token_has_all: %w[assessment:lodge] do
      correlation_id = rand
      migrated = boolean_parameter_true?("migrated")
      overridden = boolean_parameter_true?("override")

      if migrated && !env[:auth_token].scopes?(%w[migrate:assessment])
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to perform this request",
        )
      end
      logit_char_limit = 500

      sanitised_xml =
        Helper::SanitizeXmlHelper.new.sanitize(request.body.read.to_s)

      @events.event(
        false,
        {
          event_type: :lodgement_attempt,
          correlation_id: correlation_id,
          client_id: env[:auth_token].sub,
          request_body: sanitised_xml.slice(0..logit_char_limit),
          request_headers: headers,
          request_body_truncated: sanitised_xml.length > logit_char_limit,
        },
        true,
      )

      sup = env[:auth_token].supplemental("scheme_ids")
      validate_and_lodge_assessment = UseCase::ValidateAndLodgeAssessment.new

      xml_schema_type =
        if request.env["CONTENT_TYPE"]
          request.env["CONTENT_TYPE"].split("+")[1]
        else
          ""
        end
      scheme_ids = sup

      results =
        validate_and_lodge_assessment.execute(
          sanitised_xml,
          xml_schema_type,
          scheme_ids,
          migrated,
          overridden,
        )

      results.each do |result|
        @events.event(
          false,
          {
            event_type: :lodgement_successful,
            client_id: env[:auth_token].sub,
            correlation_id: correlation_id,
            assessment_id: result.get(:assessment_id),
            schema: xml_schema_type,
          },
          true,
        )
      end

      if request.env["HTTP_ACCEPT"] == "application/xml"
        builder =
          Nokogiri::XML::Builder.new do |document|
            document.response do
              document.data do
                document.assessments do
                  results.map do |result|
                    document.assessment result.get(:assessment_id)
                  end
                end
              end
              document.meta do
                document.links do
                  document.assessments do
                    results.map do |result|
                      document.assessment "/api/assessments/" +
                        result.get(:assessment_id)
                    end
                  end
                end
              end
            end
          end

        xml_response(201, builder.to_xml)
      else
        json_api_response code: 201,
                          data: {
                            assessments:
                              results.map { |id| id.get(:assessment_id) },
                          },
                          meta: {
                            links: {
                              assessments:
                                results.map do |id|
                                  "/api/assessments/" + id.get(:assessment_id)
                                end,
                            },
                          }
      end
    rescue StandardError => e
      @events.event(
        false,
        {
          event_type: :lodgement_failed,
          correlation_id: correlation_id,
          client_id: env[:auth_token]&.sub,
          error_message: e.to_s,
          schema: xml_schema_type.nil? ? "Schema not defined" : xml_schema_type,
        },
        true,
      )

      case e
      when UseCase::ValidateAssessment::InvalidXmlException
        error_response(400, "INVALID_REQUEST", e.message)
      when UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException
        error_response(400, "INVALID_REQUEST", "Schema is not supported.")
      when UseCase::CheckAssessorBelongsToScheme::AssessorNotFoundException
        error_response(400, "INVALID_REQUEST", "Assessor is not registered.")
      when UseCase::ValidateAndLodgeAssessment::SchemaNotDefined
        error_response(
          400,
          "INVALID_REQUEST",
          'Schema is not defined. Set content-type on the request to "application/xml+RdSAP-Schema-19.0" for example.',
        )
      when UseCase::ValidateAndLodgeAssessment::UnauthorisedToLodgeAsThisSchemeException
        error_response(
          403,
          "UNAUTHORISED",
          "Not authorised to lodge reports as this scheme",
        )
      when UseCase::ValidateAndLodgeAssessment::NonexistentUprn
        error_response(400, "INVALID_REQUEST", e.message)
      when UseCase::LodgeAssessment::InactiveAssessorException
        error_response(400, "INVALID_REQUEST", "Assessor is not active.")
      when UseCase::LodgeAssessment::DuplicateAssessmentIdException
        error_response(409, "INVALID_REQUEST", "Assessment ID already exists.")
      when UseCase::ValidateAndLodgeAssessment::RelatedReportError
        error_response(
          400,
          "INVALID_REQUEST",
          "Related RRNs must reference each other.",
        )
      when UseCase::ValidateAndLodgeAssessment::AddressIdsDoNotMatch
        error_response(
          400,
          "INVALID_REQUEST",
          "Both parts of a dual lodgement must share the same address id.",
        )
      when REXML::ParseException
        error_response(400, "INVALID_REQUEST", e.message)
      when UseCase::ValidateAndLodgeAssessment::LodgementRulesException
        json_response(
          400,
          {
            errors: e.errors,
            meta: {
              links: {
                override: "/api/assessments?override=true",
              },
            },
          },
        )
      else
        server_error(e)
      end
    end

    get "/api/assessments/:assessment_id",
        auth_token_has_all: %w[assessment:fetch] do
      assessment_id = params[:assessment_id]

      auth_scheme_ids = env[:auth_token].supplemental("scheme_ids")

      result =
        UseCase::FetchAssessment.new.execute(assessment_id, auth_scheme_ids)

      return xml_response(200, result)
    rescue StandardError => e
      case e
      when UseCase::FetchAssessment::NotFoundException
        not_found_error("Assessment not found")
      when UseCase::FetchAssessment::AssessmentGone
        gone_error("Assessment not for issue")
      when UseCase::FetchAssessment::SchemeIdsDoNotMatch
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to view this scheme's lodged data",
        )
      when Helper::RrnHelper::RrnNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested assessment id is not valid",
        )
      else
        server_error(e)
      end
    end

    put "/api/assessments/:assessment_id/opt-out",
        auth_token_has_all: %w[admin:opt_out] do
      assessment_id = params[:assessment_id]

      UseCase::OptOutAssessment.new.execute(assessment_id)

      json_api_response(code: 200, data: "Your opt out request was successful")
    rescue StandardError => e
      case e
      when UseCase::OptOutAssessment::AssessmentNotFound
        not_found_error("Assessment not found")
      when Helper::RrnHelper::RrnNotValid
        error_response(400, "INVALID_QUERY", "Assessment ID not valid")
      else
        server_error(e)
      end
    end

    UPDATE_ADDRESS_ID_PUT_SCHEMA = {
      type: "object",
      required: %w[addressId],
      properties: {
        addressId: {
          type: "string",
        },
      },
    }.freeze

    put "/api/assessments/:assessment_id/address-id",
        auth_token_has_all: %w[admin:update-address-id] do
      assessment_id = params[:assessment_id]
      new_address_id = request_body(UPDATE_ADDRESS_ID_PUT_SCHEMA)[:address_id]

      UseCase::UpdateAssessmentAddressId.new.execute(
        assessment_id,
        new_address_id,
      )
      json_api_response(code: 200, data: "Address ID has been updated")
    rescue StandardError => e
      case e
      when UseCase::UpdateAssessmentAddressId::AssessmentNotFound
        not_found_error("Assessment not found")
      when UseCase::UpdateAssessmentAddressId::AddressIdNotFound
        error_response(400, "BAD_REQUEST", "Address ID does not exist")
      when UseCase::UpdateAssessmentAddressId::AddressIdMismatched
        error_response(
          400,
          "BAD_REQUEST",
          "Address ID mismatched: #{e.message}",
        )
      when Helper::RrnHelper::RrnNotValid
        error_response(400, "INVALID_QUERY", "Assessment ID not valid")
      else
        server_error(e)
      end
    end
  end
end
