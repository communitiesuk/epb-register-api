# frozen_string_literal: true

module Controller
  module Scotland
    class AssessmentController < Controller::BaseController
      post "/api/scotland/assessments", auth_token_has_one_of: %w[scotland_assessment:lodge migrate:scotland] do
        correlation_id = rand
        migrated = boolean_parameter_true?("migrated")
        overridden = boolean_parameter_true?("override")

        RequestModule.relevant_request_headers = relevant_request_headers(request)

        xml_schema_type =
          if request.env["CONTENT_TYPE"]
            request.env["CONTENT_TYPE"].split("+")[1]
          else
            ""
          end

        unless xml_schema_type.include?("-S-")
          forbidden(
            "UNAUTHORISED",
            "Only Scottish schemas are supported",
          )
        end

        if !migrated && !env[:auth_token].scopes?(%w[scotland_assessment:lodge])
          forbidden(
            "UNAUTHORISED",
            "You are not authorised to perform this lodgement request",
          )
        end

        if migrated && !env[:auth_token].scopes?(%w[migrate:scotland])
          forbidden(
            "UNAUTHORISED",
            "You are not authorised to perform this migration request",
          )
        end

        logit_char_limit = 500

        sanitised_xml =
          Helper::SanitizeXmlHelper.new.sanitize(request.body.read.to_s)

        @events.event(
          false,
          {
            event_type: :lodgement_attempt,
            correlation_id:,
            client_id: env[:auth_token].sub,
            request_body: sanitised_xml.slice(0..logit_char_limit),
            request_headers: headers,
            request_body_truncated: sanitised_xml.length > logit_char_limit,
          },
          raw: true,
        )

        sup = env[:auth_token].supplemental("scheme_ids")
        validate_and_lodge_assessment = ApiFactory.validate_and_lodge_assessment_use_case

        scheme_ids = sup

        results =
          validate_and_lodge_assessment.execute(
            assessment_xml: sanitised_xml,
            schema_name: xml_schema_type,
            scheme_ids:,
            migrated:,
            overridden:,
          )

        results.each do |result|
          @events.event(
            false,
            {
              event_type: :lodgement_successful,
              client_id: env[:auth_token].sub,
              correlation_id:,
              assessment_id: result.get(:assessment_id),
              schema: xml_schema_type,
            },
            raw: true,
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
                        document.assessment "/api/scotland/assessments/#{result.get(:assessment_id)}"
                      end
                    end
                  end
                end
              end
            end

          xml_response builder.to_xml, 201
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
                                    "/api/scotland/assessments/#{id.get(:assessment_id)}"
                                  end,
                              },
                            }
        end
      rescue StandardError => e
        @events.event(
          false,
          {
            event_type: :lodgement_failed,
            correlation_id:,
            client_id: env[:auth_token]&.sub,
            error_message: e.to_s,
            schema: xml_schema_type.nil? ? "Schema not defined" : xml_schema_type,
          },
          raw: true,
        )

        case e
        when UseCase::ValidateAssessment::InvalidXmlException
          error_response(400, "INVALID_REQUEST", e.message)
        when UseCase::ValidateAndLodgeAssessment::SupersededSchemaException
          error_response(400, "INVALID_REQUEST", "This schema version has been superseded.")
        when UseCase::ValidateAndLodgeAssessment::SAPComplianceReportException
          error_response(400, "INVALID_REQUEST", "SAP Compliance Reports are not supported.")
        when UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException
          error_response(400, "INVALID_REQUEST", "Schema is not supported.")
        when Boundary::AssessorNotFoundException
          error_response(400, "INVALID_REQUEST", "Assessor is not registered.")
        when UseCase::ValidateAndLodgeAssessment::SchemaNotDefined
          error_response(
            400,
            "INVALID_REQUEST",
            'Schema is not defined. Set content-type on the request to "application/xml+RdSAP-Schema-19.0" for example.',
          )
        when UseCase::ValidateAndLodgeAssessment::SoftwareNotApprovedError
          error_response(
            400,
            "INVALID_REQUEST",
            "The calculation software used to create the assessment is not on the approved list.",
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
        when UseCase::ValidateAndLodgeAssessment::NotOverridableLodgementRuleError
          error_response(
            400,
            "INVALID_REQUEST",
            "Lodgement rule cannot be overridden: #{e.message}",
          )
        when UseCase::ValidateAndLodgeAssessment::InvalidSapDataVersionError
          error_response(
            400,
            "INVALID_REQUEST",
            "The version number #{e.invalid_version_value} for the node #{e.failed_node} is invalid for the #{e.schema_name} schema",
          )
        when UseCase::ValidateAndLodgeAssessment::LodgementFailsCountryConstraintError
          error_response(
            400,
            "INVALID_REQUEST",
            e.message,
          )
        when UseCase::ValidateAndLodgeAssessment::LodgementRulesException
          json_response(
            {
              errors: e.errors,
              meta: {
                links: {
                  override: "/api/scotland/assessments?override=true",
                },
              },
            },
            400,
          )
        else
          server_error(e)
        end
      end

      POST_ASSESSMENT_UPDATE_SCHEMA = {
        type: "object",
        required: %w[status],
        properties: {
          status: {
            type: "string",
            enum: %w[CANCELLED NOT_FOR_ISSUE],
          },
        },
      }.freeze

      post "/api/scotland/assessments/:assessment_id/status",
           auth_token_has_all: %w[scotland_assessment:lodge] do
        assessment_id = params[:assessment_id]
        assessment_body = request_body(POST_ASSESSMENT_UPDATE_SCHEMA)

        RequestModule.relevant_request_headers = relevant_request_headers(request)

        ApiFactory.update_assessment_status_use_case.execute(
          assessment_id,
          assessment_body[:status],
          env[:auth_token].supplemental("scheme_ids"),
          is_scottish: true,
        )

        json_api_response(code: 200, data: { "status": assessment_body[:status] })
      rescue StandardError => e
        case e
        when UseCase::UpdateAssessmentStatus::AssessmentNotLodgedByScheme
          error_response(403, "NOT_ALLOWED", e.message)
        when UseCase::UpdateAssessmentStatus::AssessmentAlreadyCancelled
          gone_error(e.message)
        when UseCase::UpdateAssessmentStatus::AssessmentNotFound
          not_found_error("Assessment not found")
        when Boundary::Json::Error
          error_response(422, "INVALID_REQUEST", e.message)
        else
          server_error(e)
        end
      end

      UPDATE_OPT_OUT_PUT_SCHEMA = {
        type: "object",
        required: %w[optOut],
        properties: {
          optOut: {
            type: "boolean",
          },
        },
      }.freeze

      put "/api/scotland/assessments/:assessment_id/opt-out",
          auth_token_has_all: %w[scotland_admin:opt_out] do
        assessment_id = params[:assessment_id]
        new_opt_out_status = request_body(UPDATE_OPT_OUT_PUT_SCHEMA)[:opt_out]

        RequestModule.relevant_request_headers = relevant_request_headers(request)

        ApiFactory.opt_out_assessment_use_case.execute(assessment_id, new_opt_out_status, is_scottish: true)

        response_text = if new_opt_out_status == true
                          "Your opt out request for RRN #{params[:assessment_id]} was successful"
                        else
                          "Your opt in request for RRN #{params[:assessment_id]} was successful"
                        end

        json_api_response(code: 200, data: response_text)
      rescue StandardError => e
        case e
        when UseCase::OptOutAssessment::AssessmentNotFound
          not_found_error("Assessment not found")
        when Helper::RrnHelper::RrnNotValid
          error_response(400, "INVALID_QUERY", "Assessment ID not valid")
        when Boundary::Json::Error
          error_response(400, "INVALID_REQUEST", e.message)
        else
          server_error(e)
        end
      end
    end
  end
end
