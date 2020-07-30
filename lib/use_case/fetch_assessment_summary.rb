module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end
    def execute(assessment_id)
      xml = Gateway::AssessmentsXmlGateway.new.fetch(assessment_id)

      raise NotFoundException unless xml

      { assessment_id: assessment_id }
    end
  end
end
