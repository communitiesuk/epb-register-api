module ViewModel
  class Factory
    TYPES_OF_CEPC = %w[CEPC-8.0.0].freeze
    def create(xml, schema_type)

      if TYPES_OF_CEPC.include? schema_type
        xml_doc = Nokogiri.XML(xml)
        report_type = xml_doc.at("//CEPC:Report-Type").content
        case report_type
        when "3"
          ViewModel::Cepc::CepcWrapper.new(xml, schema_type)
        else
          raise ArgumentError.new("Invalid CEPC report type")
        end
      end
    end
  end
end
