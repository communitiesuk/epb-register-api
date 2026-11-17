# frozen_string_literal: true

module Controller
  class AssessmentSummaryController < Controller::BaseController
    get "/api/assessments/:assessment_id/summary",
        auth_token_has_all: %w[assessment:fetch] do
      assessment_id = params[:assessment_id]
      summary = UseCase::AssessmentSummary::Fetch.new.execute(assessment_id)

      json_api_response(data: summary)
    rescue UseCase::AssessmentSummary::Fetch::NotFoundException
      not_found_error("No matching assessment found")
    rescue ArgumentError => e
      error_response(400, "INVALID_QUERY", e.message)
    rescue UseCase::AssessmentSummary::Fetch::AssessmentGone
      gone_error("Assessment not for issue")
    rescue Helper::RrnHelper::RrnNotValid
      error_response(400, "INVALID_QUERY", "Assessment ID not valid")
    end
  end
end
