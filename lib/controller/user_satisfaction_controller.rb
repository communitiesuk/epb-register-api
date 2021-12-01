module Controller
  class UserSatisfactionController < Controller::BaseController
    put "/api/user-satisfaction", auth_token_has_all: %w[admin:upload_stats] do
      use_case = UseCase::SaveUserSatisfaction.new(Gateway::UserSatisfactionGateway.new)
      object = JSON.parse(request.body.read, object_class: OpenStruct)
      use_case.execute(object)
      json_api_response(code: 200, data: "User satisfaction has been saved for #{object.stats_date}")
    rescue StandardError => e
      case e
      when Boundary::InvalidDate, Boundary::ArgumentMissing, Boundary::Json::Error
        error_response(400, "INVALID_REQUEST", e.message)
      else
        server_error(e)
      end
    end
  end
end
