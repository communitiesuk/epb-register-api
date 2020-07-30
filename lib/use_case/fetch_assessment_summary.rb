module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end

    def initialize
      @assessors_gateway = Gateway::AssessorsGateway.new
    end

    def execute(assessment_id)
      result = Gateway::AssessmentsXmlGateway.new.fetch(assessment_id)

      raise NotFoundException unless result

      # TODO: Check if there are multiple reports in lodged XML and only pass the desired one to the factory

      view_model =
        ViewModel::Factory.new.create(result[:xml], result[:schema_type]).to_hash

      view_model[:assessor] = @assessors_gateway.fetch view_model[:assessor][:scheme_assessor_id]

      view_model
    end
  end
end
