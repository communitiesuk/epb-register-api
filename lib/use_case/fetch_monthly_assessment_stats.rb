module UseCase
  class FetchMonthlyAssessmentStats
    def initialize(gateway)
      @gateway = gateway
    end

    def execute
      @gateway.fetch_monthly_stats
    end
  end
end
