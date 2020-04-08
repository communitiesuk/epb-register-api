module UseCase
  class FindAssessmentsByAssessmentId
    class AssessmentIdNotValid < StandardError; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(assessment_id)
      result = @assessment_gateway.search_by_assessment_id(assessment_id)
      {
        'data': { 'assessments': result },
        'meta': { 'searchQuery': assessment_id }
      }
    end
  end
end
