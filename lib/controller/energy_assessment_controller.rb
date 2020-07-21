# frozen_string_literal: true

module Controller
  class EnergyAssessmentController < Controller::BaseController
    get "/api/assessments/search", jwt_auth: %w[assessment:search] do
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
        error_response 400, "MALFORMED_REQUEST", "Required query params missing"
      when UseCase::FindAssessmentsByPostcode::ParameterMissing
        error_response 400, "MALFORMED_REQUEST", "Required query params missing"
      when UseCase::FindAssessmentsByPostcode::AssessmentTypeNotValid
        error_response(
          400,
          "MALFORMED_REQUEST",
          "The requested assessment type is not valid",
        )
      else
        server_error(e.message)
      end
    end

    post "/api/assessments", jwt_auth: %w[assessment:lodge] do
      correlation_id = rand
      migrated = params.key?("migrated")

      if migrated && !env[:jwt_auth].scopes?(%w[migrate:assessment])
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to perform this request",
        )
      end
      logit_char_limit = 50_000

      sanitized_body =
        Helper::SanitizeXmlHelper.new.sanitize(request.body.read.to_s)

      @events.event(
        false,
        {
          event_type: :lodgement_attempt,
          correlation_id: correlation_id,
          request_body: sanitized_body.slice(0..logit_char_limit),
          request_headers: headers,
          request_body_truncated: sanitized_body.length > logit_char_limit,
        },
        true,
      )

      sup = env[:jwt_auth].supplemental("scheme_ids")
      validate_and_lodge_assessment = UseCase::ValidateAndLodgeAssessment.new

      xml = sanitized_body
      content_type = request.env["CONTENT_TYPE"].split("+")[1]
      scheme_ids = sup

      results =
        validate_and_lodge_assessment.execute(
          xml,
          content_type,
          scheme_ids,
          migrated,
        )

      results.each do |result|
        @events.event(
          false,
          {
            event_type: :lodgement_successful,
            correlation_id: correlation_id,
            assessment_id: result.get(:assessment_id),
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
          error_message: e.to_s,
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
      when UseCase::LodgeAssessment::InactiveAssessorException
        error_response(400, "INVALID_REQUEST", "Assessor is not active.")
      when UseCase::LodgeAssessment::DuplicateAssessmentIdException
        error_response(409, "INVALID_REQUEST", "Assessment ID already exists.")
      when REXML::ParseException
        error_response(400, "INVALID_REQUEST", e.message)
      when UseCase::LodgeAssessment::AssessmentRuleException
        error_response(422, "ASSESSMENT_RULE_VIOLATION", e.message)
      else
        server_error(e)
      end
    end

    get "/api/assessments/:assessment_id", jwt_auth: %w[assessment:fetch] do
      assessment_id = params[:assessment_id]

      xml = (request.env["HTTP_ACCEPT"] == "application/xml")

      result = UseCase::FetchAssessment.new.execute(assessment_id, xml)

      if xml
        xml_response(200, result)
      else
        json_api_response(code: 200, data: result)
      end
    rescue StandardError => e
      case e
      when UseCase::FetchAssessment::NotFoundException
        not_found_error("Assessment not found")
      when UseCase::FetchAssessment::AssessmentGone
        gone_error("Assessment not for issue")
      else
        server_error(e)
      end
    end
  end
end
