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
        server_error(e)
      end
    end

    get "/api/reports/:scheme_id/assessors/status",
        auth_token_has_all: %w[report:assessor:status] do
      scheme_id = params["scheme_id"]
      sup = env[:auth_token].supplemental("scheme_ids")
      unless sup.include? scheme_id.to_i
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to perform this request",
        )
      end

      events =
        UseCase::GetAssessorsStatusEventsByDate.new.filter(
          Date.parse(params["date"].nil? ? "" : params["date"]),
          scheme_id,
        )

      json_api_response(code: 200, data: { assessorStatusEvents: events })
    rescue StandardError => e
      case e
      when ArgumentError
        error_response(400, "INVALID_REQUEST", e.message)
      else
        server_error(e)
      end
    end
  end
end
