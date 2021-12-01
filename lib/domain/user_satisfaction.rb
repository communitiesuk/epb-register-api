module Domain
  class UserSatisfaction
    attr_reader :stats_date, :very_satisfied, :satisfied, :neither, :dissatisfied, :very_dissatisfied

    def initialize(stats_date, very_satisfied, satisfied, neither, dissatisfied, very_dissatisfied)
      begin
        @stats_date = Time.new(stats_date.year, stats_date.month, 1, 0, 0, 0, 0)
      rescue ArgumentError
        raise Boundary::InvalidDate
      end

      raise Boundary::ArgumentMissing, "very_satisfied" if very_satisfied.nil?
      raise Boundary::ArgumentMissing, "satisfied" if satisfied.nil?
      raise Boundary::ArgumentMissing, "neither" if neither.nil?
      raise Boundary::ArgumentMissing, "dissatisfied" if dissatisfied.nil?
      raise Boundary::ArgumentMissing, "very_dissatisfied" if very_dissatisfied.nil?

      @satisfied = satisfied
      @very_satisfied = very_satisfied
      @neither = neither
      @dissatisfied = dissatisfied
      @very_dissatisfied = very_dissatisfied
    end
  end
end
