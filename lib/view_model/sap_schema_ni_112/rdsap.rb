module ViewModel
  module SapSchemaNi112
    class Rdsap < ViewModel::SapSchemaNi112::CommonSchema

      def main_dwelling_construction_age_band_or_year
        sap_building_parts = @xml_doc.xpath("//SAP-Building-Parts/SAP-Building-Part")
        sap_building_parts.each do |sap_building_part|
          identifier = sap_building_part.at("Identifier")
          if identifier&.content == "Main Dwelling"
            return sap_building_part.at_xpath("Construction-Age-Band | Construction-Year")&.content
          end
        end
        return nil
      end
    end
  end
end
