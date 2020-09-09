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

    def cooling_plant(node)
      {
        system_number: "",
        identifier: "",
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
        },
        inspection: {},
        sizing: {},
        refrigeration: {},
        maintenance: {},
        metering: {},
        humidity_control: {},
      }
    end
  end
end
