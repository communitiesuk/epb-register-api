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

    def checklist_values(checklist)
      results =
        checklist&.element_children&.map { |node|
          checklist_item = node.name.underscore.to_sym
          {
            checklist_item => {
              state: xpath(%w[Flag], node) == "Yes", note: xpath(%w[Note], node)
            },
          }
        }&.inject(&:merge)

      results.nil? ? {} : results
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
        inspection: checklist_values(node.at("ACI-Cooling-Plant-Inspection")),
        sizing: {},
        refrigeration: {},
        maintenance: {},
        metering: {},
        humidity_control: {},
      }
    end
  end
end
