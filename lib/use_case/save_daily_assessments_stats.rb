module UseCase
  class SaveDailyAssessmentsStats
    def initialize(statistics_gateway)
      @assessment_statistics_gateway = statistics_gateway
    end

    def execute(date:, assessment_types: nil)
      @assessment_statistics_gateway.save_daily_stats(date: date, assessment_types: assessment_types)
    end
  end
end
