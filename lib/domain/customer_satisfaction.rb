module Domain
  class CustomerSatisfaction
    attr_reader :stats_date, :very_satisfied, :satisfied, :neither, :dissatisfied, :very_dissatisfied

    def initialize(stats_date, very_satisfied, satisfied, neither, dissatisfied, very_dissatisfied)
      @stats_date = Time.new(stats_date.year, stats_date.month, 1, 0, 0, 0, 0)
      @satisfied = satisfied
      @very_satisfied = very_satisfied
      @neither = neither
      @dissatisfied = dissatisfied
      @very_dissatisfied = very_dissatisfied
    end
  end
end
