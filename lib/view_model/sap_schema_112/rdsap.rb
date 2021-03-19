module ViewModel
  module SapSchema112
    class Rdsap < ViewModel::SapSchema112::CommonSchema
      def property_age_band
        nil
      end

      # DO NOT CORRECT - this typo is present in the schema XML pre 12.0
      def mechanical_ventilation
        xpath(%w[Mechanical-Ventliation])
      end

      def main_dwelling_construction_age_band_or_year
        sap_building_parts =
          @xml_doc.xpath("//SAP-Building-Parts/SAP-Building-Part")
        sap_building_parts.each do |sap_building_part|
          identifier = sap_building_part.at("Identifier")
          if identifier&.content == "Main Dwelling"
            return(
              sap_building_part.at_xpath(
                "Construction-Age-Band | Construction-Year",
              )&.content
            )
          end
        end
        nil
      end
    end
  end
end
