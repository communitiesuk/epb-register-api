module UseCase
  class FindAssessmentsByAssessmentId
    class AssessmentIdNotValid < StandardError; end

    def initialize
      @assessment_gateway = Gateway::AssessmentsGateway.new
    end

    def execute(assessment_id)
      result = @assessment_gateway.search_by_assessment_id(assessment_id)

      new = []

      result.each { |row| new.push(row.to_hash) }

      { data: new, search_query: assessment_id }
    end
  end
end
