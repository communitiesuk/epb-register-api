module ViewModel
  module SapSchema110
    class Sap < ViewModel::SapSchema110::CommonSchema
      def property_age_band
        construction_year
      end

      def construction_year
        xpath(%w[Construction-Year])
      end

      def main_dwelling_construction_age_band_or_year
        sap_building_parts =
          @xml_doc.xpath("//SAP-Building-Parts/SAP-Building-Part")
        sap_building_parts.each do |sap_building_part|
          construction_year = sap_building_part.at("Construction-Year")
          if construction_year&.content
            return sap_building_part.at_xpath("Construction-Year")&.content
          end
        end
        nil
      end
    end
  end
end
