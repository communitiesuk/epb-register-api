module UseCase
  class FindAssessmentsByStreetNameAndTown
    class PostcodeNotValid < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(street_name, town)
      result =
        @assessment_gateway.search_by_street_name_and_town(street_name, town)
      { 'results': result, 'searchQuery': [street_name, town] }
    end
  end
end
