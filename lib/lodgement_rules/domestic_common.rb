module LodgementRules
  class DomesticCommon
    def self.method_or_nil(adapter, method)
      Helper::ClassHelper.method_or_nil(adapter, method)
    end

    RULES = [
      {
        name: "MUST_HAVE_HABITABLE_ROOMS",
        title:
          '"Habitable-Room-Count" must be an integer and must be greater than or equal to 1',
        test:
          lambda do |adapter, _country_lookup = nil|
            habitable_room_count = method_or_nil(adapter, :habitable_room_count)
            return true if habitable_room_count.nil?

            begin
              Integer(habitable_room_count) >= 1
            rescue StandardError
              false
            end
          end,
      },
      {
        name: "RATINGS_MUST_BE_POSITIVE",
        title:
          '"Energy-Rating-Current", "Energy-Rating-Potential", "Environmental-Impact-Current" and "Environmental-Impact-Potential" must be greater than 0',
        test:
          lambda do |adapter, _country_lookup = nil|
            ratings = [
              method_or_nil(adapter, :energy_rating_current),
              method_or_nil(adapter, :energy_rating_potential),
              method_or_nil(adapter, :environmental_impact_current),
              method_or_nil(adapter, :environmental_impact_potential),
            ]
            ratings.compact.map(&:to_i).select { |rating| rating <= 0 }.empty?
          end,
      },
      {
        name: "MUST_HAVE_DESCRIPTION",
        title:
          '"Description" for parent node "Wall", "Walls", "Roof", "Floor", "Window", "Windows", "Main-Heating", "Main-Heating-Controls", "Hot-Water", "Lighting" and "Secondary-Heating" must not be equal to the parent node name, ignoring case',
        test:
          lambda do |adapter, _country_lookup = nil|
            walls = method_or_nil(adapter, :all_wall_descriptions)
            if !walls.nil? && !walls.compact.select { |desc|
                 desc.casecmp("wall").zero?
               }.empty?
              return false
            end

            roofs = method_or_nil(adapter, :all_roof_descriptions)
            if !roofs.nil? && !roofs.compact.select { |desc|
                 desc.casecmp("roof").zero?
               }.empty?
              return false
            end

            floors = method_or_nil(adapter, :all_floor_descriptions)
            if !floors.nil? && !floors.compact.select { |desc|
                 desc.casecmp("floor").zero?
               }.empty?
              return false
            end

            windows = method_or_nil(adapter, :all_window_descriptions)
            if !windows.nil? && !windows.compact.select { |desc|
                 desc.casecmp("window").zero?
               }.empty?
              return false
            end

            main_heating =
              method_or_nil(adapter, :all_main_heating_descriptions)
            if !main_heating.nil? && !main_heating.compact.select { |desc|
                 desc.casecmp("main-heating").zero?
               }.empty?
              return false
            end

            main_heating_controls =
              method_or_nil(adapter, :all_main_heating_controls_descriptions)
            if !main_heating_controls.nil? && !main_heating_controls.compact.select { |desc|
                 desc.casecmp("main-heating-controls").zero?
               }.empty?
              return false
            end

            hot_water = method_or_nil(adapter, :all_hot_water_descriptions)
            if !hot_water.nil? && !hot_water.compact.select { |desc|
                 desc.casecmp("hot-water").zero?
               }.empty?
              return false
            end

            lighting = method_or_nil(adapter, :all_lighting_descriptions)
            if !lighting.nil? && !lighting.compact.select { |desc|
                 desc.casecmp("lighting").zero?
               }.empty?
              return false
            end

            secondary_heating =
              method_or_nil(adapter, :all_secondary_heating_descriptions)
            if !secondary_heating.nil? && !secondary_heating.compact.select { |desc|
                 desc.casecmp("secondary-heating").zero?
               }.empty?
              return false
            end

            true
          end,
      },
      {
        name: "SAP_FLOOR_AREA_RANGE",
        title:
          '"Total-Floor-Area" within "SAP-Floor-Dimension" must be greater than 0 and less than or equal to 3000',
        test:
          lambda do |adapter, _country_lookup = nil|
            sap_floor_dimensions =
              method_or_nil(adapter, :all_sap_floor_dimensions)

            sap_floor_dimensions.compact.map { |dimension| dimension[:total_floor_area] }.compact.select { |area| area <= 0 || area > 3000 }.empty?
          end,
      },
      {
        name: "GROUND_FLOOR_HEAT_LOSS_ON_UPPER_FLOOR",
        title:
          'If "Level" is greater than 1 and "Building-Part-Number" is equal to 1 then "Floor-Heat-Loss" must not be equal to 7',
        test:
          lambda do |adapter, _country_lookup = nil|
            level = method_or_nil(adapter, :level)
            building_part_number = method_or_nil(adapter, :building_part_number)
            floor_heat_loss = method_or_nil(adapter, :floor_heat_loss)

            !(
              level.to_i > 1 && building_part_number == "1" &&
                floor_heat_loss == "7"
            )
          end,
      },
      {
        name: "SUPPLY_IMMERSION_HEATER_TYPE",
        title:
          'If "Water-Heating-Code" is equal to 903 then "Immersion-Heating-Type" must not be equal to \'NA\'',
        test:
          lambda do |adapter, _country_lookup = nil|
            water_heating_code = method_or_nil(adapter, :water_heating_code)
            immersion_heating_type =
              method_or_nil(adapter, :immersion_heating_type)

            !(water_heating_code == "903" && immersion_heating_type == "NA")
          end,
      },
      {
        name: "SUPPLY_BOILER_FLUE_TYPE",
        title:
          'If "Main-Heating-Category" is equal to 2 and "Main-Fuel-Type" is equal to 17, 18, 26, 27, 28, 34, 35, 36, 37 or 51 then "Boiler-Flue-Type" must be supplied',
        test:
          lambda do |adapter, _country_lookup = nil|
            heating_category = method_or_nil(adapter, :main_heating_category)
            fuel_type = method_or_nil(adapter, :main_fuel_type)
            boiler_flue_type = method_or_nil(adapter, :boiler_flue_type)

            relevant_fuel_types = %w[17 18 26 27 28 34 35 36 37 51]

            !(
              heating_category == "2" &&
                relevant_fuel_types.include?(fuel_type) && boiler_flue_type.nil?
            )
          end,
      },
      {
        name: "DATES_CANT_BE_IN_FUTURE",
        title:
          '"Inspection-Date", "Registration-Date" and "Completion-Date" must not be in the future',
        test:
          lambda do |adapter, _country_lookup = nil|
            dates = [
              method_or_nil(adapter, :date_of_assessment),
              method_or_nil(adapter, :date_of_registration),
              method_or_nil(adapter, :date_of_completion),
            ]
            dates.none? { |date| Date.parse(date).future? }
          end,
      },
      {
        name: "DATES_IN_RANGE",
        title:
          '"Inspection-Date", "Registration-Date" and "Completion-Date" must not be more than 18 months ago',
        test:
          lambda do |adapter, _country_lookup = nil|
            dates = [
              Date.parse(method_or_nil(adapter, :date_of_assessment)),
              Date.parse(method_or_nil(adapter, :date_of_registration)),
              Date.parse(method_or_nil(adapter, :date_of_completion)),
            ]

            dates.reject { |date|
              date.after?(Date.today.prev_month(18))
            }.empty?
          end,
      },
      {
        name: "INVALID_HEATING_FOR_SINGLE_METER",
        title:
          'If "Meter-Type" is equal to 2 then "SAP-Main-Heating-Code" must not be equal to 401, 402, 404, 408, 409, 421 or 422',
        test:
          lambda do |adapter, _country_lookup = nil|
            relevant_heating_codes = %w[401 402 404 408 409 421 422]
            meter_type = method_or_nil(adapter, :meter_type)
            sap_main_heating_code =
              method_or_nil(adapter, :sap_main_heating_code)

            !(
              meter_type == "2" &&
                relevant_heating_codes.include?(sap_main_heating_code)
            )
          end,
      },
      {
        name: "SUPPLY_ROOF_U_VALUE_OR_INSULATION_THICKNESS",
        title:
          'Only one of "Roof-Insulation-Thickness", "Rafter-Insulation-Thickness", "Flat-Roof-Insulation-Thickness", "Sloping-Ceiling-Insulation-Thickness" or "Roof-U-Value" may be supplied',
        test:
          lambda do |adapter, _country_lookup = nil|
            building_parts = method_or_nil(adapter, :all_building_parts)

            building_parts.select { |part|
              [
                part[:roof_insulation_thickness],
                part[:rafter_insulation_thickness],
                part[:flat_roof_insulation_thickness],
                part[:sloping_ceiling_insulation_thickness],
                part[:roof_u_value],
              ].count { |p| !p.nil? } > 1
            }.empty?
          end,
      },
      {
        name: "SUPPLY_MULTIPLE_BUILDING_PARTS",
        title:
          'If "Roof-Room-Connected" is equal to \'Y\' or \'y\' then more than one "SAP-Building-Part" must be supplied',
        test:
          lambda do |adapter, _country_lookup = nil|
            building_parts = method_or_nil(adapter, :all_building_parts)
            roof_room_connected = !building_parts.map { |part| part[:roof_room_connected] }.select { |flag| flag&.upcase == "Y" }.empty?
            !(roof_room_connected && building_parts.length <= 1)
          end,
      },
      {
        name: "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE",
        title:
          'The "Completion-Date" must be equal to or later than "Inspection-Date"',
        test:
          lambda do |adapter, _country_lookup = nil|
            dates = [
              Date.parse(method_or_nil(adapter, :date_of_assessment)),
              # Inspection-Date
              Date.parse(method_or_nil(adapter, :date_of_completion)),
              # Completion-Date
            ]
            dates[0] <= dates[1]
          end,
      },
      {
        name: "COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE",
        title:
          'The "Completion-Date" must be before or equal to the "Registration-Date"',
        test:
          lambda do |adapter, _country_lookup = nil|
            dates = [
              Date.parse(method_or_nil(adapter, :date_of_completion)),
              # Completion-Date
              Date.parse(method_or_nil(adapter, :date_of_registration)),
              # Registration-Date
            ]

            dates[0] <= dates[1]
          end,
      },
      {
        name: "INVALID_COUNTRY",
        title:
          "Property address must be in England, Wales, or Northern Ireland",
        test:
          lambda do |adapter, country_lookup = nil|
            country_code = method_or_nil(adapter, :country_code)
            if country_lookup.in_channel_islands? || country_lookup.in_isle_of_man? || (country_lookup.in_scotland? && !country_lookup.in_england?) || country_code == "SCT"
              false
            else
              true
            end
          end,
      },
    ].freeze

    def validate(xml_adaptor, country_lookup)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor, country_lookup) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
