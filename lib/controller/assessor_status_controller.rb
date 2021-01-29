module Controller
  class AssessorStatusController < Controller::BaseController
    get "/api/reports/assessors/status",
        auth_token_has_all: %w[report:assessor:status] do
      events =
        UseCase::GetAssessorsStatusEventsByDate.new.execute(
          Date.parse(params["date"].nil? ? "" : params["date"]),
        )

      json_api_response(code: 200, data: { assessorStatusEvents: events })
    rescue StandardError => e
      case e
      when ArgumentError
        error_response(400, "INVALID_REQUEST", e.message)
      else
        server_error(e.message)
      end
    end
  end
end
