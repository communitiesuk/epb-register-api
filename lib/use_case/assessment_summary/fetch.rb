module UseCase
  module AssessmentSummary
    class Fetch
      class AssessmentUnavailable < StandardError; end
      class NotFoundException < AssessmentUnavailable; end
      class AssessmentGone < AssessmentUnavailable; end

      def initialize(search_gateway: nil, xml_gateway: nil)
        @search_gateway = search_gateway || Gateway::AssessmentsSearchGateway.new
        @xml_gateway = xml_gateway || Gateway::AssessmentsXmlGateway.new
      end

      def execute(assessment_id, method = "to_hash")
        assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
        assessment =
          @search_gateway
            .search_by_assessment_id(assessment_id, restrictive: false)
            .first

        if assessment
          if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
            raise AssessmentGone
          end
        else
          raise NotFoundException
        end

        lodged_xml_document =
          @xml_gateway.fetch assessment_id
        raise NotFoundException unless lodged_xml_document

        lodged_values =
          lodged_values_from_xml(
            lodged_xml_document[:xml],
            lodged_xml_document[:schema_type],
            assessment_id,
          )
        assessment_table_values = assessment.to_hash

        summary_data = if method == "to_certificate_summary"
                         lodged_values.to_certificate_summary
                       else
                         lodged_values.to_hash
                       end
        # Update *both* address_id places as they are both used at different points in code elsewhere
        if method == "to_hash"
          summary_data[:address] = (summary_data[:address] || {}).merge(address_id: assessment_table_values[:address_id])
        end
        summary_data[:address_id] = assessment_table_values[:address_id]
        summary_data[:opt_out] = assessment_table_values[:opt_out]

        case lodged_values.type
        when :AC_CERT
          AcCertSupplement.new.add_data!(summary_data)
        when :AC_REPORT
          AcReportSupplement.new.add_data!(summary_data)
        when :CEPC
          CepcSupplement.new.add_data!(summary_data)
        when :CEPC_RR
          CepcRrSupplement.new.add_data!(summary_data)
        when :DEC
          DecSupplement.new.add_data!(summary_data)
        when :DEC_RR
          DecRrSupplement.new.add_data!(summary_data)
        when :SAP
          SapSupplement.new.add_data!(summary_data, method)
        when :RdSAP
          RdSapSupplement.new.add_data!(summary_data, method)
        else
          summary_data
        end
      end

    private

      def lodged_values_from_xml(xml, schema_type, assessment_id)
        view_model =
          ViewModel::Factory.new.create(xml, schema_type, assessment_id)
        unless view_model
          raise ArgumentError,
                "Assessment summary unsupported for this assessment type"
        end
        view_model
      end
    end
  end
end
