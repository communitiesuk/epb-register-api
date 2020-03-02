module UseCase
  class FindAssessmentsByAssessmentId
    class AssessmentIdNotValid < Exception; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(assessment_id)
      result = @assessment_gateway.search_by_assessment_id(assessment_id)
      { 'results': result, 'searchQuery': assessment_id }
    end
  end
end
