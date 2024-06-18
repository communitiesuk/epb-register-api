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
        return_hash[key_name(country:)] = stats
      end

      return_hash
    end

  private

    def key_name(country:)
      str = country.include?("&") ? country.delete("&") : country
      str.downcase.parameterize(separator: "_").to_sym
    end
  end
end
