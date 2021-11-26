module Controller
  class CustomerSatisfactionController < Controller::BaseController
    # get "/api/customer-satisfaction",
    #     auth_token_has_all: %w[statistics:fetch] do
    #   use_case = UseCase::FetchMonthlyAssessmentStats.new(Gateway::AssessmentStatisticsGateway.new)
    #   report = use_case.execute
    #   json_api_response(data: report[:all])
    # end

    put "/api/customer-satisfaction", auth_token_has_all: %w[admin:opt_out] do
      use_case = UseCase::SaveCustomerSatisfaction.new(Gateway::CustomerSatisfactionGateway.new)
      object = JSON.parse(request.body.read, object_class: OpenStruct)
      use_case.execute(object)
      json_api_response(code: 200, data: "Customer satisfaction has been saved")
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
