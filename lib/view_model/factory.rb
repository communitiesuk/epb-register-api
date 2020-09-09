module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[
      CEPC-8.0.0
      CEPC-NI-8.0.0
      CEPC-7.1
      CEPC-7.0
      CEPC-6.0
    ].freeze
    TYPES_OF_RD_SAP = %w[
      RdSAP-Schema-20.0.0
      RdSAP-Schema-NI-20.0.0
      RdSAP-Schema-19.0
      RdSAP-Schema-NI-19.0
    ].freeze
    TYPES_OF_SAP = %w[
      SAP-Schema-18.0.0
      SAP-Schema-NI-18.0.0
      SAP-Schema-17.1
      SAP-Schema-NI-17.1
    ].freeze
    def create(xml = nil, schema_type = nil, filter_results_for = nil)
      xml_doc = Nokogiri.XML(xml).remove_namespaces!

      if TYPES_OF_CEPC.include? schema_type
        filtered_results =
          if filter_results_for
            xml_doc.at("//*[RRN=\"#{filter_results_for}\"]/ancestor::Report")
          else
            xml_doc
          end

        report_type = filtered_results.at("Report-Type").content

        case report_type
        when "1"
          ViewModel::DecWrapper.new(filtered_results.to_xml, schema_type)
        when "2"
          ViewModel::DecRrWrapper.new(filtered_results.to_xml, schema_type)
        when "3"
          ViewModel::CepcWrapper.new(filtered_results.to_xml, schema_type)
        when "4"
          ViewModel::CepcRrWrapper.new(filtered_results.to_xml, schema_type)
        when "5"
          ViewModel::AcReportWrapper.new(filtered_results.to_xml, schema_type)
        when "6"
          ViewModel::AcCertWrapper.new(filtered_results.to_xml, schema_type)
        else
          raise ArgumentError, "Invalid CEPC report type"
        end
      elsif TYPES_OF_RD_SAP.include?(schema_type)
        ViewModel::RdSapWrapper.new(xml_doc.to_xml, schema_type)
      elsif TYPES_OF_SAP.include?(schema_type)
        ViewModel::SapWrapper.new(xml_doc.to_xml, schema_type)
      end
    end
  end
end
