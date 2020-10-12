module Helper
  class AcReportExtraction
    def xpath(queries, node = @xml_doc)
      queries.each do |query|
        if node
          node = node.at query
        else
          return nil
        end
      end
      node ? node.content : nil
    end

    def checklist_values(checklist, skip_state = false)
      results =
        checklist&.element_children&.map { |node|
          next if xpath(%w[Flag], node).nil? && !skip_state

          checklist_item = node.name.underscore.to_sym
          if skip_state
            { checklist_item => { note: xpath(%w[Note], node) } }
          else
            {
              checklist_item => {
                state: xpath(%w[Flag], node) == "Yes",
                note: xpath(%w[Note], node),
              },
            }
          end
        }&.compact.inject(&:merge)

      results.nil? ? {} : results
    end

    def checklist_values_with_guidance(checklist)
      results =
        checklist&.element_children&.map { |node|
          next if xpath(%w[Flag], node).nil?

          checklist_item = node.name.underscore.to_sym

          {
            checklist_item => {
              state: xpath(%w[Flag], node) == "Yes",
              note: xpath(%w[Note], node),
              guidance: xpath(%w[Text], node),
            },
          }
        }&.compact.inject(&:merge)

      results.nil? ? {} : results
    end

    def guidance(guidance_elements)
      guidance_elements&.element_children&.map do |element|
        {
          seq_number: xpath(%w[Seq-Number], element),
          code: xpath(%w[Code], element),
          text: xpath(%w[Text], element),
        }
      end
    end

    def cooling_plant(node)
      {
        system_number: xpath(%w[System-Number], node),
        identifier: xpath(%w[System-Component-Identifier], node),
        equipment: {
          manufacturer: xpath(%w[Manufacturer], node),
          description: xpath(%w[Description], node),
          model_reference: xpath(%w[Model-Reference], node),
          serial_number: xpath(%w[Serial-Number], node),
          year_installed: xpath(%w[Year-Installed], node),
          cooling_capacity: xpath(%w[Cooling-Capacity], node),
          refrigerant_type: {
            type: xpath(%w[Type], node),
            ecfgasregulation: xpath(%w[ECFGasRegulation], node),
            ecozoneregulation: xpath(%w[ECOzoneRegulation], node),
          },
          refrigerant_charge: xpath(%w[Refrigerant-Charge], node),
          location: xpath(%w[Location], node),
          area_served: xpath(%w[Area-Served], node),
          discrepancy_note: xpath(%w[Discrepancy-Note], node),
        },
        inspection:
          checklist_values_with_guidance(
            node.at("ACI-Cooling-Plant-Inspection"),
          ),
        sizing: {
          total_occupants:
            xpath(%w[ACI-Cooling-Plant-Sizing/Total-Occupants], node),
          total_floor_area:
            xpath(%w[ACI-Cooling-Plant-Sizing/Total-Floor-Area], node),
          occupant_density:
            xpath(%w[ACI-Cooling-Plant-Sizing/Occupant-Density], node),
          upper_heat_gain:
            xpath(%w[ACI-Cooling-Plant-Sizing/Upper-Heat-Gain], node),
          installed_capacity:
            xpath(%w[ACI-Cooling-Plant-Sizing/Installed-Capacity], node),
          acceptable_installed_size:
            xpath(%w[ACI-Cooling-Plant-Sizing/Acceptable-Installed-Size], node),
          guidance: guidance(node.at("ACI-Cooling-Plant-Sizing/Guidance")),
        },
        refrigeration: {
          refrigerant_name:
            xpath(%w[ACI-Cooling-Plant-Refrigeration/Refrigerant-Name], node),
          f_gas_inspection:
            checklist_values(node.at("ACI-Cooling-Plant-Refrigeration"))[
              :f_gas_inspection
            ],
          pre_compressor:
            xpath(%w[ACI-Cooling-Plant-Refrigeration/Pre-Compressor], node),
          post_processor:
            xpath(%w[ACI-Cooling-Plant-Refrigeration/Post-Processor], node),
          ambient: xpath(%w[ACI-Cooling-Plant-Refrigeration/Ambient], node),
          acceptable_temperature:
            xpath(
              %w[ACI-Cooling-Plant-Refrigeration/Acceptable-Temperature],
              node,
            ),
          compressor_control:
            checklist_values(node.at("ACI-Cooling-Plant-Refrigeration"), true)[
              :compressor_control
            ],
          refrigerant_leak:
            checklist_values(node.at("ACI-Cooling-Plant-Refrigeration"))[
              :refrigerant_leak
            ],
          guidance:
            guidance(node.at("ACI-Cooling-Plant-Refrigeration/Guidance")),
        },
        maintenance: {
          records_kept:
            checklist_values(node.at("ACI-Cooling-Plant-Maintenance"))[
              :records_kept
            ],
          competent_person:
            checklist_values(node.at("ACI-Cooling-Plant-Maintenance"))[
              :competent_person
            ],
          guidance: guidance(node.at("ACI-Cooling-Plant-Maintenance/Guidance")),
        },
        metering: checklist_values(node.at("ACI-Cooling-Plant-Metering")),
        humidity_control:
          checklist_values(node.at("ACI-Cooling-Plant-Humidity-Control"))[
            :humidity_control
          ],
        chillers:
          if xpath(%w[ACI-Cooling-Plant-Chillers], node).nil?
            {}
          else
            checklist_values(node.at("ACI-Cooling-Plant-Chillers"))
          end,
      }
    end
  end
end
