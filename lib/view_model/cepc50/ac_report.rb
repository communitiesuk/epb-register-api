module ViewModel
  module Cepc50
    class AcReport < ViewModel::Cepc50::CommonSchema
      def related_party_disclosure
        xpath(%w[Related-Party-Disclosure])
      end

      def executive_summary
        xpath(%w[Executive-Summary])
      end

      def extract_aci_recommendations(nodes)
        nodes.map { |node|
          {
            sequence: node.at("Seq-Number").content,
            text: node.at("Text").content,
          }
        }.reject { |node| node[:text].nil? || node[:text].empty? }
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
        @xml_doc
          .search("ACI-Sub-Systems/ACI-Sub-System")
          .map do |node|
            {
              volume_definitions:
                node.at("Sub-System-Volume-Definitions")&.content,
              id: node.at("Sub-System-ID")&.content,
              description: node.at("Sub-System-Description")&.content,
              cooling_output: node.at("Sub-System-Cooling-Output")&.content,
              area_served:
                node.at("Sub-System-Area-Served-Description")&.content,
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
        @xml_doc
          .search("Air-Conditioning-Inspection-Report/ACI-Cooling-Plant")
          .map { |_node| {} }
      end

      def checklist_values(checklist)
        results =
          checklist&.element_children&.map { |node|
            checklist_item = node.name.underscore.to_sym
            value = node.content == "Yes"
            { checklist_item => value }
          }&.inject(&:merge)

        results.nil? ? {} : results
      end

      def pre_inspection_checklist
        pcs_essential =
          checklist_values(
            @xml_doc.at(
              "PCS-Pre-Inspection-Information/PCS-Pre-Inspection-Essential",
            ),
          )
        pcs_desirable =
          checklist_values(
            @xml_doc.at(
              "PCS-Pre-Inspection-Information/PCS-Pre-Inspection-Desirable",
            ),
          )
        pcs_optional =
          checklist_values(
            @xml_doc.at(
              "PCS-Pre-Inspection-Information/PCS-Pre-Inspection-Optional",
            ),
          )

        sccs_essential =
          checklist_values(
            @xml_doc.at(
              "SCCS-Pre-Inspection-Information/SCCS-Pre-Inspection-Essential",
            ),
          )
        sccs_desirable =
          checklist_values(
            @xml_doc.at(
              "SCCS-Pre-Inspection-Information/SCCS-Pre-Inspection-Desirable",
            ),
          )
        sccs_optional =
          checklist_values(
            @xml_doc.at(
              "SCCS-Pre-Inspection-Information/SCCS-Pre-Inspection-Optional",
            ),
          )

        {
          pcs: {
            essential: pcs_essential,
            desirable: pcs_desirable,
            optional: pcs_optional,
          },
          sccs: {
            essential: sccs_essential,
            desirable: sccs_desirable,
            optional: sccs_optional,
          },
        }
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
