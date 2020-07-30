# frozen_string_literal: true

module Controller
  class AssessmentSummaryController < Controller::BaseController
    get "/api/assessments/:assessment_id/summary", jwt_auth: %w[assessment:fetch] do
      not_found_error("Assessment ID not found")
    end
  end
end
