module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[CEPC-8.0.0].freeze
    TYPES_OF_RD_SAP = %w[RdSAP-Schema-20.0.0]
    def create(xml = nil, schema_type = nil, filter_results_for = nil, allow_domestic = false)
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
            ViewModel::DecRrWrapper.new(
              filtered_results.to_xml,
              schema_type,
            )
          when "3"
            ViewModel::CepcWrapper.new(filtered_results.to_xml, schema_type)
          when "4"
            ViewModel::CepcRrWrapper.new(filtered_results.to_xml, schema_type)
          else
            raise ArgumentError, "Invalid CEPC report type"
          end

      elsif (TYPES_OF_RD_SAP.include? schema_type) && allow_domestic
        ViewModel::RdSapWrapper.new(xml_doc.to_xml, schema_type)
        end
      end
  end
end
