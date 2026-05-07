module LodgementRules
  class ScottishRdsap
    def self.method_or_nil(adapter, method)
      Helper::ClassHelper.method_or_nil(adapter, method)
    end

    RULES = [
      {
        name: "SCOTLAND_INSPECTION_DATE_LATER_THAN_COMPLETION_DATE_VAL009",
        title:
          "Date of dwelling survey (inspection date) cannot be any later than date of lodgement of data to the register",
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
        name: "SCOTLAND_INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE_VAL010",
        title:
          "Date of dwelling survey (inspection date) should not be more than three months earlier than the completion date",
        test:
          lambda do |adapter, _country_lookup = nil|
            inspection_date = Date.parse(method_or_nil(adapter, :date_of_assessment))

            completion_date = Date.parse(method_or_nil(adapter, :date_of_completion))

            limit_date = inspection_date >> 3

            completion_date <= limit_date
          end,
      },
      {
        name: "SCOTLAND_COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT_VAL011",
        title:
          "Date of certificate declared is not the same as date of lodgement to the register",
        test:
          lambda do |adapter, _country_lookup = nil|
            completion_date = Date.parse(method_or_nil(adapter, :date_of_completion))

            completion_date == Date.today
          end,
      },
      {
        name: "SCOTLAND_PARTY_WALLS_ARE_NOT_APPLICABLE_FOR_DETACHED_PROPERTIES_VAL001",
        title:
          "When the build form for a property is detached, party walls must be recorded as not applicable",
        test:
          lambda do |adapter, _country_lookup = nil|
            built_form = method_or_nil(adapter, :built_form)

            party_walls_construction = method_or_nil(adapter, :party_walls_construction)

            party_walls_exist = party_walls_construction.any? { |v| v != "NA" }

            !(built_form == "1" && party_walls_exist)
          end,
      },
      {
        name: "SCOTLAND_PARTY_WALLS_ARE_NOT_DEFINED_USING_CURRENT_SURVEY_INFORMATION_VAL003",
        title:
          "Party walls must be defined using current survey information",
        test:
          lambda do |adapter, _country_lookup = nil|
            party_walls_construction = method_or_nil(adapter, :party_walls_construction)

            party_walls_no_information = party_walls_construction.any? { |v| v != "NI" }

            party_walls_no_information
          end,
      },
      {
        name: "SCOTLAND_TOTAL_FLOOR_AREA_LESS_THAN_30_VAL012",
        title:
          "Very small total floor area (<30) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            total_floor_area = method_or_nil(adapter, :total_floor_area)

            (total_floor_area.to_f > 30.0)
          end,
      },
      {
        name: "SCOTLAND_TOTAL_FLOOR_AREA_GREATER_THAN_299_VAL013",
        title:
          "Very large total floor area (>299) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            total_floor_area = method_or_nil(adapter, :total_floor_area)

            (total_floor_area.to_f < 299.0)
          end,
      },
      {
        name: "SCOTLAND_PRIMARY_ENERGY_VALUE_LESS_THAN_50_VAL015",
        title:
          "Very low primary energy value (<50) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            primary_energy_use = method_or_nil(adapter, :primary_energy_use)

            (primary_energy_use.to_f > 50.0)
          end,
      },
      {
        name: "SCOTLAND_PRIMARY_ENERGY_VALUE_GREATER_THAN_849_VAL016",
        title:
          "Very high primary energy value (>849) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            primary_energy_use = method_or_nil(adapter, :primary_energy_use)

            (primary_energy_use.to_f < 849.0)
          end,
      },
      {
        name: "SCOTLAND_WALL_THICKNESS_GREATER_THAN_801_VAL004",
        title:
          "Unusually think walls (>801) reported for dwelling part",
        test:
          lambda do |adapter, _country_lookup = nil|
            walls_thickness = method_or_nil(adapter, :walls_thickness)

            thick_walls = walls_thickness.any? { |v| v[:wall_thickness].to_i > 801 }
            alternative_wall_thickness = walls_thickness.any? { |v| v[:alternative_wall_thickness].to_i > 801 }

            if thick_walls || alternative_wall_thickness
              false
            else
              true
            end
          end,
      },
      {
        name: "SCOTLAND_WALL_THICKNESS_LESS_THAN_140_NOT_PARK_HOME_OR_SYSTEM_BUILT_VAL006",
        title:
          "Very low wall thickness (<140) reported and construction not park home or system built",
        test:
          lambda do |adapter, _country_lookup = nil|
            walls_thickness = method_or_nil(adapter, :walls_thickness)

            thin_walls = walls_thickness&.any? do |hash|
              if hash[:wall_thickness].nil? && hash[:alternative_wall_thickness].nil?
                false
              elsif hash[:wall_thickness].nil?
                (hash[:alternative_wall_thickness].to_i < 140) && %w[10 8].none?(hash[:alternative_wall_construction])
              elsif hash[:alternative_wall_thickness].nil?
                (hash[:wall_thickness].to_i < 140) && %w[10 8].none?(hash[:wall_construction])
              else
                ((hash[:wall_thickness].to_i < 140) && %w[10 8].none?(hash[:wall_construction])) || ((hash[:alternative_wall_thickness].to_i < 140) && %w[10 8].none?(hash[:alternative_wall_construction]))
              end
            end

            !thin_walls
          end,
      },
      {
        name: "SCOTLAND_WALL_THICKNESS_LESS_THAN_230_WITH_CAVITY_VAL007",
        title:
          "Wall thickness of less than 230mm reported for cavity wall construction",
        test:
          lambda do |adapter, _country_lookup = nil|
            walls_thickness = method_or_nil(adapter, :walls_thickness)

            thin_walls = walls_thickness&.any? do |hash|
              if hash[:wall_thickness].nil? && hash[:alternative_wall_thickness].nil?
                false
              elsif hash[:wall_thickness].nil?
                (hash[:alternative_wall_thickness].to_i < 230) && (hash[:alternative_wall_construction] == "4")
              elsif hash[:alternative_wall_thickness].nil?
                (hash[:wall_thickness].to_i < 230) && (hash[:wall_construction] == "4")
              else
                ((hash[:wall_thickness].to_i < 230) && (hash[:wall_construction] == "4")) || ((hash[:alternative_wall_thickness].to_i < 230) && (hash[:alternative_wall_construction] == "4"))
              end
            end

            !thin_walls
          end,
      },
      {
        name: "SCOTLAND_WALL_THICKNESS_MEASURED_IS_N_BUT_WALL_THICKNESS_PRESENT_VAL008",
        title:
          "Wall thickness recorded as not measured but wall thickness value provided by assessor",
        test:
          lambda do |adapter, _country_lookup = nil|
            walls_thickness = method_or_nil(adapter, :walls_thickness)

            thin_walls = walls_thickness&.any? do |hash|
              if hash[:wall_thickness].nil? && hash[:alternative_wall_thickness].nil?
                false
              elsif hash[:wall_thickness].nil?
                hash[:alternative_wall_construction].present? && hash[:alternative_wall_thickness_measured] == "N"
              elsif hash[:alternative_wall_thickness].nil?
                hash[:wall_construction].present? && hash[:wall_thickness_measured] == "N"
              else
                (hash[:wall_construction].present? && hash[:wall_thickness_measured] == "N") || (hash[:alternative_wall_construction].present? && hash[:alternative_wall_thickness_measured] == "N")
              end
            end

            !thin_walls
          end,
      },
      {
        name: "SCOTLAND_10_OR_MORE_HABITABLE_ROOMS_VAL002",
        title:
          "High number of habitable rooms - 10 or more",
        test:
          lambda do |adapter, _country_lookup = nil|
            habitable_room_count = method_or_nil(adapter, :habitable_room_count)

            (habitable_room_count.to_i < 9)
          end,
      },
      {
        name: "SCOTLAND_ROOF_INSULATION_LOCATION_CANNOT_BE_5_VAL050",
        title:
          "Roof insulation location can only be 5 when roof construction is 4, 5 or 6",
        test:
          lambda do |adapter, _country_lookup = nil|
            rooves_construction_and_insulation = method_or_nil(adapter, :rooves_construction_and_insulation)

            incorrect_roof_insulation = rooves_construction_and_insulation&.any? do |hash|
              if hash[:roof_insulation_location].to_i != 5
                false
              elsif (hash[:roof_insulation_location].to_i == 5) && [4, 5, 6].include?(hash[:roof_construction].to_i)
                false
              else
                true
              end
            end

            !incorrect_roof_insulation
          end,
      },
      {
        name: "SCOTLAND_INSULATION_IN_ROOM_IN_ROOF_IS_1_VAL051",
        title:
          "The insulation for room in roof cannot be 1",
        test:
          lambda do |adapter, _country_lookup = nil|
            rooms_in_roof_insulation = method_or_nil(adapter, :rooms_in_roof_insulation)

            room_insulation_1 = rooms_in_roof_insulation&.any? do |room_in_roof_insulation|
              %w[1].include?(room_in_roof_insulation)
            end

            !room_insulation_1
          end,
      },
      {
        name: "SCOTLAND_FLOOR_INSULATION_THICKNESS_AND_FLOOR_U_VALUE_CANNOT_BOTH_BE_PRESENT_VAL052",
        title:
          "Either floor insulation thickness or floor u value can be present but not both. It is possible for neither to be present",
        test:
          lambda do |adapter, _country_lookup = nil|
            floors_insulation = method_or_nil(adapter, :floors_insulation)

            both_floor_measurements_present = floors_insulation&.any? do |floor_insulation|
              if floor_insulation[:floor_u_value].present? && floor_insulation[:floor_insulation_thickness].present?
                true
              else
                false
              end
            end

            !both_floor_measurements_present
          end,
      },
      {
        name: "SCOTLAND_ONLY_ONE_ROOF_INSULATION_VALUE_PERMITTED_VAL053",
        title:
          "One one of the following should be present: Roof-Insulation-Thickness, Roof-U-Value, Rafter-Insulation-Thickness, Flat-Roof-Insulation-Thickness, Sloping-Ceiling-Insulation-Thickness",
        test:
          lambda do |adapter, _country_lookup = nil|
            rooves_insulation = method_or_nil(adapter, :rooves_insulation)

            multiple_insulation_types_present = rooves_insulation&.any? do |roof_insulation|
              data_array = roof_insulation.values.reject { |element| element.nil? || element.empty? }

              data_array&.count != 1
            end

            !multiple_insulation_types_present
          end,
      },
      {
        name: "SCOTLAND_ONLY_ONE_WALL_INSULATION_VALUE_PERMITTED_VAL054",
        title:
          "One one of the following should be present: Wall-Insulation-Thickness, Wall-U-Value",
        test:
          lambda do |adapter, _country_lookup = nil|
            walls_insulation = method_or_nil(adapter, :walls_insulation)

            both_wall_measurements_present = walls_insulation&.any? do |wall_insulation|
              if (wall_insulation[:wall_u_value].present? && wall_insulation[:wall_insulation_thickness].present?) || (wall_insulation[:wall_u_value].nil? && wall_insulation[:wall_insulation_thickness].nil?)
                true
              else
                false
              end
            end

            !both_wall_measurements_present
          end,
      },
      {
        name: "SCOTLAND_ONLY_ONE_ROOM_IN_ROOF_INSULATION_VALUE_PERMITTED_VAL055",
        title:
          "One one of the following should be present: Roof-Insulation-Thickness, Room-In-Roof-Details",
        test:
          lambda do |adapter, _country_lookup = nil|
            rooms_in_roof = method_or_nil(adapter, :rooms_in_roof).reject { |element| element.nil? || element.empty? }

            rooms_in_roof_roof_insulation = method_or_nil(adapter, :rooms_in_roof_roof_insulation)

            both_roof_measurements_present = false

            unless rooms_in_roof.empty?
              both_roof_measurements_present = rooms_in_roof_roof_insulation&.any? do |roof_insulation|
                roof_insulation[:room_in_roof_details].present? ==
                  roof_insulation[:roof_insulation_thickness].present?
              end
            end

            !both_roof_measurements_present
          end,
      },
      {
        name: "SCOTLAND_ONLY_ONE_ALTERNATIVE_WALL_INSULATION_VALUE_PERMITTED_VAL056",
        title:
          "One one of the following should be present for an alternative wall: Wall-Insulation-Thickness, Wall-U-Value",
        test:
          lambda do |adapter, _country_lookup = nil|
            walls_thickness = method_or_nil(adapter, :walls_thickness)

            both_wall_insulations_present = walls_thickness&.any? do |wall_insulation|
              wall_insulation[:alternative_wall_construction].present? &&
                (
                  wall_insulation[:alternative_wall_u_value].present? ==
                    wall_insulation[:alternative_wall_insulation_thickness].present?
                )
            end

            !both_wall_insulations_present
          end,
      },
      {
        name: "SCOTLAND_ONLY_ONE_MAIN_HEATING_VALUE_PERMITTED_VAL057",
        title:
          "One one of the following should be present for main heating: Main-Heating-Index-Number, SAP-Main-Heating-Code",
        test:
          lambda do |adapter, _country_lookup = nil|
            main_heating_details = method_or_nil(adapter, :main_heating_details)

            both_main_heating_present = main_heating_details&.any? do |main_heating|
              main_heating[:main_heating_index_number].present? ==
                main_heating[:sap_main_heating_code].present?
            end

            !both_main_heating_present
          end,
      },
      {
        name: "SCOTLAND_MAIN_HEATING_CODE_MUST_BE_699_OR_310_VAL059",
        title:
          "Main-Fuel-Type may only be 0 when Main-Heating-Code is either 699 and 310",
        test:
          lambda do |adapter, _country_lookup = nil|
            main_heating_details = method_or_nil(adapter, :main_heating_details)

            wrong_heating_code = main_heating_details&.any? do |main_heating|
              main_heating[:main_fuel_type] == "0" &&
                !%w[699 310].include?(main_heating[:sap_main_heating_code])
            end

            !wrong_heating_code
          end,
      },
      {
        name: "SCOTLAND_WATER_HEATING_CODE_MUST_BE_999_OR_953_VAL060",
        title:
          "Water-Heating-Fuel may only be 0 when Water-Heating-Code is either 999 and 953",
        test:
          lambda do |adapter, _country_lookup = nil|
            water_heating = method_or_nil(adapter, :water_heating)

            if (water_heating[:water_heating_fuel] == "0") && !%w[999 953].include?(water_heating[:water_heating_code])
              false
            else
              true
            end
          end,
      },
      {
        name: "INVALID_COUNTRY",
        title:
          "Property address must be in Scotland",
        test:
          lambda do |adapter, country_lookup = nil|
            country_code = method_or_nil(adapter, :country_code)
            if country_lookup.in_channel_islands? || country_lookup.in_isle_of_man? || (!country_lookup.in_scotland? && country_lookup.in_england?) || country_lookup.in_wales? || country_lookup.in_northern_ireland? || country_code == "EAW" || country_code == "ENG" || country_code == "WLS" || country_code == "NI"
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
