module UseCase
  class FindAssessmentsByAssessmentId
    def initialize(assessments_search_gateway: Gateway::AssessmentsSearchGateway.new)
      @assessment_gateway = assessments_search_gateway
    end

    def execute(assessment_id, is_scottish: false)
      assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)

      result = @assessment_gateway.search_by_assessment_id(assessment_id, restrictive: false, is_scottish: is_scottish)

      new = []

      result.each { |row| new.push(row.to_hash(is_scottish:)) }

      { data: new, search_query: assessment_id }
    end
  end
end
