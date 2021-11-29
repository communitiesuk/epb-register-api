module Controller
  class StatisticsController < Controller::BaseController
    get "/api/statistics",
        auth_token_has_all: %w[statistics:fetch] do
      assessment_use_case = UseCase::FetchMonthlyAssessmentStats.new(Gateway::AssessmentStatisticsGateway.new)
      customer_use_case = UseCase::FetchCustomerSatisfaction.new(Gateway::CustomerSatisfactionGateway.new)
      json_api_response(data: { assessments: assessment_use_case.execute, customer: customer_use_case.execute })
    end

    get "/api/statistics/new",
        auth_token_has_all: %w[statistics:fetch] do
      assessment_use_case = UseCase::FetchMonthlyAssessmentStats.new(Gateway::AssessmentStatisticsGateway.new)
      # customer_use_case = UseCase::FetchCustomerSatisfaction.new(Gateway::CustomerSatisfactionGateway.new)
      json_api_response(data: assessment_use_case.execute)
    end
  end
end
