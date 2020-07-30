module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end
    def execute(assessment_id)
      xml = Gateway::AssessmentsXmlGateway.new.fetch(assessment_id)

      raise NotFoundException unless xml

      view_model = ViewModel::Factory.new.create(xml, "CEPC-8.0.0")

      view_model.to_hash
    end
  end
end
