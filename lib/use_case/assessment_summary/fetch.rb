module UseCase
  module AssessmentSummary
    class Fetch
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

      def lodged_values_from_xml(xml, schema_type, assessment_id)
        view_model =
          ViewModel::Factory.new.create(xml, schema_type, assessment_id)
        unless view_model
          raise ArgumentError,
                "Assessment summary unsupported for this assessment type"
        end
        view_model
      end

      def execute(assessment_id)
        assessment =
          Gateway::AssessmentsGateway.new.search_by_assessment_id(
            assessment_id,
            false,
          ).first

        if assessment
          if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
            raise AssessmentGone
          end
        else
          raise NotFoundException
        end

        lodged_xml_document =
          Gateway::AssessmentsXmlGateway.new.fetch assessment_id
        raise NotFoundException unless lodged_xml_document

        lodged_values =
          lodged_values_from_xml(
            lodged_xml_document[:xml],
            lodged_xml_document[:schema_type],
            assessment_id,
          )

        full_summary =
          case lodged_values.type
          when :CEPC
            CepcSupplement.new.add_data!(lodged_values.to_hash)
          when :CEPC_RR
            CepcRrSupplement.new.add_data!(lodged_values.to_hash)
          when :DEC
            DecSupplement.new.add_data!(lodged_values.to_hash)
          when :SAP
            SapSupplement.new.add_data!(lodged_values.to_hash)
          when :RdSAP
            RdSapSupplement.new.add_data!(lodged_values.to_hash)
          else
            lodged_values.to_hash
          end

        full_summary
      end
    end
  end
end
