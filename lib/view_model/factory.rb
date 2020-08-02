module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[CEPC-8.0.0].freeze
    def create(xml = nil, schema_type = nil, filter_results_for = nil)

      if TYPES_OF_CEPC.include? schema_type
        xml_doc = Nokogiri.XML(xml).remove_namespaces!

        filtered_results = filter_results_for ?
                               xml_doc.at("//*[RRN=\"#{filter_results_for}\"]/ancestor::Report")
                               :
                               xml_doc

        report_type = filtered_results.at("Report-Type").content

        case report_type
        when "3"
          ViewModel::Cepc::CepcWrapper.new(filtered_results.to_xml, schema_type)
        when "4"
          ViewModel::CepcRr::CepcRrWrapper.new(filtered_results.to_xml, schema_type)
        else
          raise ArgumentError, "Invalid CEPC report type"
        end
      end
    end
  end
end
