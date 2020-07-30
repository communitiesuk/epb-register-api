module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end
    def execute(assessment_id)
      result = Gateway::AssessmentsXmlGateway.new.fetch(assessment_id)

      raise NotFoundException unless result

      view_model =
        ViewModel::Factory.new.create(result[:xml], result[:schema_type])

      view_model.to_hash
    end
  end
end
