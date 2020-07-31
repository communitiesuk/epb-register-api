module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end

    def other_values_for_cepc(cepc_hash)
      assessor_id = cepc_hash[:assessor][:scheme_assessor_id]
      assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)

      cepc_hash[:assessor][:registered_by] = {
        name: assessor.registered_by_name, scheme_id: assessor.registered_by_id
      }
      cepc_hash
    end

    def build_view_model_from_xml_attributes(xml, schema_type)
      view_model = ViewModel::Factory.new.create(xml, schema_type)
      unless view_model
        raise ArgumentError,
              "Assessment summary unsupported for this assessment type"
      end
      view_model
    end

    def execute(assessment_id)
      lodged_xml_document = Gateway::AssessmentsXmlGateway.new.fetch assessment_id
      raise NotFoundException unless lodged_xml_document

      # TODO: Check if there are multiple reports in lodged XML and only pass the desired one to the factory

      lodged_values = build_view_model_from_xml_attributes(
          lodged_xml_document[:xml],
          lodged_xml_document[:schema_type])

      case lodged_values.type
      when :CEPC
        full_summary = other_values_for_cepc(lodged_values.to_hash)
      else
        full_summary = lodged_values.to_hash
      end

      full_summary
    end
  end
end
