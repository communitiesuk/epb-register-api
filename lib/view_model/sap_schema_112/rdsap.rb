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

      def glazed_area
        xpath(%w[Glazed-Area])
      end

      def window_description
        xpath(%w[Window Description])
      end

      def window_energy_efficiency_rating
        xpath(%w[Window Energy-Efficiency-Rating])
      end

      def window_environmental_efficiency_rating
        xpath(%w[Window Environmental-Efficiency-Rating])
      end

      def all_wall_descriptions
        @xml_doc.search("Wall/Description").map(&:content)
      end

      def all_wall_energy_efficiency_rating
        @xml_doc.search("Wall/Energy-Efficiency-Rating").map(&:content)
      end

      def all_wall_env_energy_efficiency_rating
        @xml_doc.search("Wall/Environmental-Efficiency-Rating").map(&:content)
      end

      def habitable_room_count
        xpath(%w[Habitable-Room-Count])
      end

      def heated_room_count
        xpath(%w[Heated-Room-Count])
      end

      def heat_loss_corridor
        xpath(%w[Heat-Loss-Corridor])
      end
    end
  end
end
