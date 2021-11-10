module Controller
  class StatisticsController < Controller::BaseController
    get "/api/statistics",
        auth_token_has_all: %w[statistics:fetch] do
      use_case = UseCase::FetchMonthlyAssessmentStats.new(Gateway::AssessmentStatisticsGateway.new)
      report = use_case.execute
      json_api_response(data: report)
    end
  end
end
