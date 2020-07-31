module UseCase
  class FetchAssessmentSummary
    class NotFoundException < StandardError; end
    ASSESSMENT_WITHOUT_XML =
      "Request will succeed on fetch assessment endpoint, summary unavailable because XML not lodged"
        .freeze

    def supported_in_legacy_route?(assessment_id)
      !Gateway::AssessmentsGateway.new.search_by_assessment_id(
        assessment_id,
        false,
      ).empty?
    end

    def add_cepc_supplementary_values!(cepc_hash)
      assessor_id = cepc_hash[:assessor][:scheme_assessor_id]
      assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)

      cepc_hash[:assessor][:registered_by] = {
        name: assessor.registered_by_name, scheme_id: assessor.registered_by_id
      }

      related_assessments =
        Gateway::RelatedAssessmentsGateway.new.by_address_id cepc_hash[
                                                               :address
                                                             ][
                                                               :address_id
                                                             ]

      cepc_hash[:related_assessments] = related_assessments

      cepc_hash
    end

    def lodged_values_from_xml(xml, schema_type)
      view_model = ViewModel::Factory.new.create(xml, schema_type)
      unless view_model
        raise ArgumentError,
              "Assessment summary unsupported for this assessment type"
      end
      view_model
    end

    def execute(assessment_id)
      lodged_xml_document =
        Gateway::AssessmentsXmlGateway.new.fetch assessment_id
      unless lodged_xml_document
        if supported_in_legacy_route?(assessment_id)
          raise ArgumentError, ASSESSMENT_WITHOUT_XML
        else
          raise NotFoundException
        end
      end

      lodged_values =
        lodged_values_from_xml(
          lodged_xml_document[:xml],
          lodged_xml_document[:schema_type],
        )

      full_summary =
        case lodged_values.type
        when :CEPC
          add_cepc_supplementary_values!(lodged_values.to_hash)
        else
          lodged_values.to_hash
        end

      full_summary
    end
  end
end
