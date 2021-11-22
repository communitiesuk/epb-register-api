module UseCase
  class FetchMonthlyAssessmentStats
    def initialize(gateway)
      @gateway = gateway
    end

    def execute
      country_stats = @gateway.fetch_monthly_stats_by_country
      { all: @gateway.fetch_monthly_stats,
        england_wales: country_stats.select { |stats| stats["country"] == "England & Wales" },
        northern_ireland: country_stats.select { |stats| stats["country"] == "Northern Ireland" } }
    end
  end
end
