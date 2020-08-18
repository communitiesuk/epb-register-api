module Controller
  class AssessorStatusController < Controller::BaseController
    get "/api/reports/assessors/status", jwt_auth: %w[report:assessor:status] do
      json_api_response(code: 200, data: { assessorStatusEvents: [] })
    end
  end
end
