module UseCase
  class FetchMonthlyAssessmentStats
    def initialize(gateway)
      @gateway = gateway
    end

    def execute
      country_stats = @gateway.fetch_monthly_stats_by_country

      return_hash = { all: @gateway.fetch_monthly_stats }

      group_by_country = country_stats.group_by { |stat| stat["country"] }.transform_values(&:flatten)

      group_by_country.each_with_object({}) do |(country, stats), _h|
        country_key = country.downcase.parameterize(separator: "_").to_sym
        return_hash[country_key] = stats
      end

      return_hash
    end
  end
end
