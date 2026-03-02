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
  end
end
