module UseCase
  class FindAssessmentsByStreetNameAndTown
    class ParameterMissing < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(street_name, town)
      raise ParameterMissing if street_name.blank? || town.blank?

      result =
        @assessment_gateway.search_by_street_name_and_town(street_name, town)
      {
        'data': { 'assessments': result },
        'meta': { 'searchQuery': [street_name, town] }
      }
    end
  end
end
