# frozen_string_literal: true

module Controller
  class AssessmentSummaryController < Controller::BaseController
    get "/api/assessments/:assessment_id/summary",
        jwt_auth: %w[assessment:fetch] do
      assessment_id = params[:assessment_id]
      summary = UseCase::AssessmentSummary::Fetch.new.execute(assessment_id)

      json_api_response(data: summary)
    rescue StandardError => e
      case e
      when UseCase::AssessmentSummary::Fetch::NotFoundException
        not_found_error("No matching assessment found")
      when ArgumentError
        error_response(400, "INVALID_QUERY", e.message)
      when UseCase::AssessmentSummary::Fetch::AssessmentGone
        gone_error("Assessment not for issue")
      else
        server_error(e)
      end
    end
  end
end
