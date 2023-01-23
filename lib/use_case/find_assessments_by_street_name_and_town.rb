module UseCase
  class FindAssessmentsByStreetNameAndTown
    class ParameterMissing < StandardError
    end

    MAX_RESULTS_THRESHOLD = 200

    def initialize(gateway = nil)
      @assessment_gateway = gateway || Gateway::AssessmentsSearchGateway.new
    end

    def execute(street_name, town, assessment_type)
      raise ParameterMissing if street_name.blank? || town.blank?

      result =
        @assessment_gateway.search_by_street_name_and_town(
          street_name,
          town,
          assessment_type,
          limit: MAX_RESULTS_THRESHOLD + 1,
        )
      raise Boundary::TooManyResults if result.length > MAX_RESULTS_THRESHOLD

      Helper::NaturalSort.sort!(result)

      { data: result.map(&:to_hash), search_query: [street_name, town] }
    end
  end
end
