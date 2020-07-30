module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end

    def other_values_for_cepc(cepc_hash)
      assessor_id = cepc_hash[:assessor][:scheme_assessor_id]
      assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)

      cepc_hash[:assessor][:registered_by] = {
          name: assessor.registered_by_name,
          scheme_id: assessor.registered_by_id
      }
      cepc_hash
    end

    def execute(assessment_id)
      result = Gateway::AssessmentsXmlGateway.new.fetch assessment_id

      raise NotFoundException unless result

      # TODO: Check if there are multiple reports in lodged XML and only pass the desired one to the factory

      view_model =
        ViewModel::Factory.new.create(result[:xml], result[:schema_type])

      raise ArgumentError, "Assessment summary unsupported for this assessment type" unless view_model

      view_model_with_merged_attributes = other_values_for_cepc(view_model.to_hash)
      view_model_with_merged_attributes
    end
  end
end
