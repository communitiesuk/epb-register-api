module ViewModel
  module CepcNi800
    class AcReport < ViewModel::CepcNi800::CommonSchema
      def related_party_disclosure
        xpath(%w[ACI-Related-Party-Disclosure])
      end

      def executive_summary
        xpath(%w[Executive-Summary])
      end

      def equipment_owner_name
        xpath(%w[Equipment-Owner Equipment-Owner-Name])
      end

      def equipment_owner_telephone
        xpath(%w[Equipment-Owner Telephone-Number])
      end

      def equipment_owner_organisation
        xpath(%w[Equipment-Owner Organisation-Name])
      end

      def equipment_owner_address_line1
        xpath(%w[Equipment-Owner Registered-Address Address-Line-1])
      end

      def equipment_owner_address_line2
        xpath(%w[Equipment-Owner Registered-Address Address-Line-2])
      end

      def equipment_owner_address_line3
        xpath(%w[Equipment-Owner Registered-Address Address-Line-3])
      end

      def equipment_owner_address_line4
        xpath(%w[Equipment-Owner Registered-Address Address-Line-4])
      end

      def equipment_owner_town
        xpath(%w[Equipment-Owner Registered-Address Post-Town])
      end

      def equipment_owner_postcode
        xpath(%w[Equipment-Owner Registered-Address Postcode])
      end

      def operator_responsible_person
        xpath(%w[Equipment-Operator Responsible-Person])
      end

      def operator_telephone
        xpath(%w[Equipment-Operator Telephone-Number])
      end

      def operator_organisation
        xpath(%w[Equipment-Operator Organisation-Name])
      end

      def operator_address_line1
        xpath(%w[Equipment-Operator Registered-Address Address-Line-1])
      end

      def operator_address_line2
        xpath(%w[Equipment-Operator Registered-Address Address-Line-2])
      end

      def operator_address_line3
        xpath(%w[Equipment-Operator Registered-Address Address-Line-3])
      end

      def operator_address_line4
        xpath(%w[Equipment-Operator Registered-Address Address-Line-4])
      end

      def operator_town
        xpath(%w[Equipment-Operator Registered-Address Post-Town])
      end

      def operator_postcode
        xpath(%w[Equipment-Operator Registered-Address Postcode])
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
            "ACI-Key-Recommendations/Sub-System-Efficiency-Capacity-Cooling-Loads/ACI-Recommendation",
          ),
        )
      end

      def key_recommendations_maintenance
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Key-Recommendations/Improvement-Options/ACI-Recommendation",
          ),
        )
      end

      def key_recommendations_control
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Key-Recommendations/Alternative-Solutions/ACI-Recommendation",
          ),
        )
      end

      def key_recommendations_management
        extract_aci_recommendations(
          @xml_doc.search(
            "ACI-Key-Recommendations/Other-Recommendations/ACI-Recommendation",
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

      def cooling_plants
        extraction_helper = Helper::AcReportExtraction.new

        @xml_doc.search("Air-Conditioning-Inspection-Report/ACI-Cooling-Plant")
          .map { |node| extraction_helper.cooling_plant(node) }
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
        {
          essential:
            checklist_values(
              @xml_doc.at(
                "ACI-Pre-Inspection-Information/ACI-Pre-Inspection-Essential",
              ),
            ),
          desirable:
            checklist_values(
              @xml_doc.at(
                "ACI-Pre-Inspection-Information/ACI-Pre-Inspection-Desirable",
              ),
            ),
          optional:
            checklist_values(
              @xml_doc.at(
                "ACI-Pre-Inspection-Information/ACI-Pre-Inspection-Optional",
              ),
            ),
        }
      end

      def extract_inspection_item(node)
        inspection_item = {
            note: node&.at("Note")&.content,
            recommendations:
                extract_aci_recommendations(node.search("ACI-Recommendation")),
        }

        flag = node.at("Flag")

        if flag
          inspection_item[:flag] = flag.content == "Yes"
        end
        inspection_item
      end

      def air_handling_systems
        @xml_doc.search("ACI-Air-Handling-System").map do |node|
          {
              equipment: {
                  unit: node.at("System-Number")&.content,
                  component: node.at("System-Component-Identifier")&.content,
                  systems_served:
                      node.at("ACI-Air-Handling-System-Equipment/Systems-Served")
                          &.content,
                  manufacturer:
                      node.at("ACI-Air-Handling-System-Equipment/Manufacturer")
                          &.content,
                  year_installed:
                      node.at("ACI-Air-Handling-System-Equipment/Year-Installed")
                          &.content,
                  location:
                      node.at("ACI-Air-Handling-System-Equipment/Location")&.content,
                  areas_served:
                      node.at("ACI-Air-Handling-System-Equipment/Area-Served")
                          &.content,
                  discrepancy:
                      node.at("ACI-Air-Handling-System-Equipment/Discrepancy-Note")
                          &.content,
              },
              inspection: {
                  filters: {
                      filter_condition:
                          extract_inspection_item(node.at("Filter-Condition-OK")),
                      change_frequency:
                          extract_inspection_item(node.at("Filter-Change-Frequency-OK")),
                      differential_pressure_gauge:
                          extract_inspection_item(node.at("Differential-Pressure-Gauge-OK")),
                  },
                  heat_exchangers: {
                      condition: extract_inspection_item(node.at("Heat-Exchangers-OK"))
                  },
                  refrigeration: {
                      leaks: extract_inspection_item(node.at("Refrigeration-Leak"))
                  },
                  fan_rotation: {
                      direction: extract_inspection_item(node.at("Fan-Rotation-OK")),
                      modulation: extract_inspection_item(node.at("Fan-Modulation-OK")),
                  }
              },
          }
        end
      end
    end
  end
end
