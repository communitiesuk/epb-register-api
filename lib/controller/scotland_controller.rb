# frozen_string_literal: true

module Controller
  class ScotlandController < Controller::BaseController
    get "/api/scotland/assessments/:assessment_id/certificate-summary",
        auth_token_has_all: %w[scotland_assessment:fetch] do
      assessment_id = params[:assessment_id]
      summary = UseCase::CertificateSummary::Fetch.new.execute(assessment_id, is_scottish: true)

      json_api_response(data: summary)
    rescue StandardError => e
      case e
      when UseCase::CertificateSummary::Fetch::NotFoundException
        not_found_error("No matching assessment found")
      when ArgumentError
        error_response(400, "INVALID_QUERY", e.message)
      when UseCase::CertificateSummary::Fetch::AssessmentGone
        gone_error("Assessment not for issue")
      when Helper::RrnHelper::RrnNotValid
        error_response(400, "INVALID_QUERY", "Assessment ID not valid")
      when Boundary::InvalidAssessment
        error_response(400, "INVALID_QUERY", e.message)
      else
        server_error(e)
      end
    end

    get "/api/scotland/assessments/search", auth_token_has_all: %w[scotland_assessment:search] do
      assessment_types = params[:assessmentTypes] ? params[:assessmentTypes].split(",") : []
      assessment_id = params[:assessmentId]
      street = params[:street]

      result =
        if params.key?(:postcode)
          UseCase::FindAssessmentsByPostcode.new.execute(
            params[:postcode],
            assessment_types,
            is_scottish: true,
          )
        elsif !assessment_id.nil?
          UseCase::FindAssessmentsByAssessmentId.new.execute(
            assessment_id,
            is_scottish: true,
          )
        else
          ApiFactory.find_assessments_by_street_name_and_town.execute(
            street,
            params[:town],
            assessment_types,
            is_scottish: true,
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
        error_response(400, "INVALID_REQUEST", "The requested postcode is not valid")
      when UseCase::FindAssessmentsByPostcode::AssessmentTypeNotValid
        error_response(400, "INVALID_REQUEST", "The requested assessment type is not valid")
      when Helper::RrnHelper::RrnNotValid
        error_response(400, "INVALID_REQUEST", "The requested assessment id is not valid")
      when Boundary::TooManyResults
        error_response(413, "PAYLOAD_TOO_LARGE", "There are too many results")
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

    get "/api/scotland/assessors", auth_token_has_all: %w[scotland_assessor:search] do
      postcode = params[:postcode]
      qualifications = params[:qualification]

      if postcode.nil? || qualifications.nil?
        error_response(
          400,
          "INVALID_QUERY",
          "Must specify postcode & qualification when searching",
        )
      else
        postcode.upcase
        postcode.insert(-4, " ") if postcode[-4] != " "

        result =
          UseCase::FindAssessorsByPostcode.new.execute(
            postcode,
            qualifications.split(","),
            is_scottish: true,
          )

        result[:data] = assessor_list_results_filter(result)

        json_api_response(code: 200, data: result, burrow_key: :assessors)
      end
    rescue StandardError => e
      case e
      when UseCase::FindAssessorsByPostcode::PostcodeNotRegistered
        not_found_error("The requested postcode is not registered")
      when UseCase::FindAssessorsByPostcode::PostcodeNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested postcode is not valid",
        )
      when ArgumentError
        error_response(400, "INVALID_QUERY", e.message)
      else
        server_error(e)
      end
    end

    def assessor_list_results_filter(unfiltered_results)
      if unfiltered_results[:data]
        unfiltered_results[:data].map do |r|
          r.slice(
            :registered_by,
            :scheme_assessor_id,
            :first_name,
            :last_name,
            :middle_names,
            :date_of_birth,
            :email,
            :telephone_number,
            :search_results_comparison_postcode,
            :contact_details,
            :qualifications,
            :distance_from_postcode_in_miles,
          )
        end
      end
    end
  end
end
