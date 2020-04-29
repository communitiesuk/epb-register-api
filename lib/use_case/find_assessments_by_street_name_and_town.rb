module UseCase
  class FindAssessmentsByStreetNameAndTown
    class ParameterMissing < StandardError; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(street_name, town)
      raise ParameterMissing if street_name.blank? || town.blank?

      result =
        @assessment_gateway.search_by_street_name_and_town(street_name, town)

      opt_out_filtered_results = []

      result.each do |r|
        opt_out_filtered_results << r unless r[:opt_out] == true
      end
      {
        data: opt_out_filtered_results,
        search_query: [street_name, town]
      }
    end
  end
end
