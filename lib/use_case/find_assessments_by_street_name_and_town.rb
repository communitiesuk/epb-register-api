module UseCase
  class FindAssessmentsByStreetNameAndTown
    class ParameterMissing < StandardError
    end

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
        )
      raise Boundary::TooManyResults if result.length > 200 && Helper::Toggles.enabled?("register-api-limit-street-town-results")

      Helper::NaturalSort.sort!(result)

      { data: result.map(&:to_hash), search_query: [street_name, town] }
    end
  end
end
