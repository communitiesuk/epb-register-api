module ViewModel
  module Cepc60
    class AcReport < ViewModel::Cepc60::CommonSchema
      def related_party_disclosure
        xpath(%w[Related-Party-Disclosure])
      end

      def executive_summary
        xpath(%w[Executive-Summary])
      end

      def extract_aci_recommendations(nodes)
        nodes.map do |node|
          {
            sequence: node.at("Seq-Number").content,
            text: node.at("Text").content,
          }
        end
      end

      def key_recommendations_efficiency
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Recommendations/System-Efficiency/ACI-Recommendation",
          ),
        )
      end

      def key_recommendations_maintenance
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Recommendations/Improvement-Options/ACI-Recommendation",
          ),
        )
      end

      def key_recommendations_control
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Recommendations/Alternative-Solutions/ACI-Recommendation",
          ),
        )
      end

      def key_recommendations_management
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Recommendations/Other-Recommendations/ACI-Recommendation",
          ),
        )
      end

      def sub_systems
        @xml_doc.search("ACI-Sub-Systems/ACI-Sub-System").map do |node|
          {
            volume_definitions:
              node.at("Sub-System-Volume-Definitions")&.content,
            id: node.at("Sub-System-ID")&.content,
            description: node.at("Sub-System-Description")&.content,
            cooling_output: node.at("Sub-System-Cooling-Output")&.content,
            area_served: node.at("Sub-System-Area-Served-Description")&.content,
            inspection_date: node.at("Sub-System-Inspection-Date")&.content,
            cooling_plant_count:
              node.at("Sub-System-Cooling-Plant-Count")&.content,
            ahu_count: node.at("Sub-System-AHU-Count")&.content,
            terminal_units_count:
              node.at("Sub-System-Terminal-Units-Count")&.content,
            controls_count: node.at("Sub-System-Controls-Count")&.content,
          }
        end
      end

      def related_rrn
        xpath(%w[Related-RRN])
      end

      def cooling_plants
        @xml_doc.search("Air-Conditioning-Inspection-Report/ACI-Cooling-Plant")
          .map { |_node| {} }
      end

      def pre_inspection_checklist
        {}
      end

      def air_handling_systems
        []
      end

      def terminal_units
        []
      end

      def system_controls
        []
      end
    end
  end
end
