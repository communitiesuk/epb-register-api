module Controller
  class StatisticsController < Controller::BaseController
    get "/api/statistics",
        auth_token_has_all: %w[statistics:fetch] do
      assessment_use_case = UseCase::FetchMonthlyAssessmentStats.new(Gateway::AssessmentStatisticsGateway.new)
      user_use_case = UseCase::FetchUserSatisfaction.new(Gateway::UserSatisfactionGateway.new)
      json_api_response(data: { assessments: assessment_use_case.execute, user: user_use_case.execute })
    end

    get "/api/statistics/new",
        auth_token_has_all: %w[statistics:fetch] do
      assessment_use_case = UseCase::FetchMonthlyAssessmentStats.new(Gateway::AssessmentStatisticsGateway.new)
      json_api_response(data: assessment_use_case.execute)
    end

    get "/api/interesting-numbers", auth_token_has_all: %w[statistics:fetch] do
      reports = ApiFactory.fetch_data_warehouse_reports_use_case.execute
      json_api_response(data: reports.map(&:to_hash), code: reports.incomplete? ? 202 : 200)
    end
  end
end
