module ViewModel
  module SapSchema102
    class Rdsap < ViewModel::SapSchema102::CommonSchema
      def property_age_band
        nil
      end

      def construction_age_band
        xpath(%w[Construction-Year])
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

      def glazed_area
        xpath(%w[Glazed-Area])
      end

      def habitable_room_count
        xpath(%w[Habitable-Room-Count])
      end

      def heated_room_count
        xpath(%w[Heated-Room-Count])
      end

      def photovoltaic_roof_area_percent
        xpath(%w[Photovoltaic-Supply])
      end

      def solar_water_heating_flag
        xpath(%w[Solar-Water-Heating])
      end

      def floor_height
        @xml_doc.search("Room-Height").map(&:content)
      end

      def storey_count
        xpath(%w[Storey-Count])
      end

      def energy_tariff
        xpath(%w[Meter-Type])
      end
    end
  end
end
