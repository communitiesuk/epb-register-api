module UseCase
  class FindAssessmentsByAssessmentId
    def initialize
      @assessment_gateway = Gateway::AssessmentsSearchGateway.new
    end

    def execute(assessment_id)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      result = @assessment_gateway.search_by_assessment_id(assessment_id)

      new = []

      result.each { |row| new.push(row.to_hash) }

      { data: new, search_query: assessment_id }
    end
  end
end
