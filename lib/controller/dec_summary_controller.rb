module Controller
  class DecSummaryController < Controller::BaseController
    get "/api/dec_summary/:assessment_id", jwt_auth: %w[dec_summary:fetch] do
      error_response(403, "NOT_A_DEC", "Assessment is not a DEC")
    end
  end
end
