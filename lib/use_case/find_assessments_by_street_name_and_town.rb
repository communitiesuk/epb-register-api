module UseCase
  class FindAssessmentsByStreetNameAndTown
    class ParameterMissing < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(street_name, town)
      if street_name.blank? || town.blank?
        raise ParameterMissing
      end

      result =
        @assessment_gateway.search_by_street_name_and_town(street_name, town)
      { 'results': result, 'searchQuery': [street_name, town] }
    end
  end
end
