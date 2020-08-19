module Controller
  class AssessorStatusController < Controller::BaseController
    get "/api/reports/assessors/status", jwt_auth: %w[report:assessor:status] do
      events =
        UseCase::GetAssessorsStatusEventsByDate.new.execute(
          Date.parse(params["date"]),
        )

      json_api_response(code: 200, data: { assessorStatusEvents: events })
    end
  end
end
