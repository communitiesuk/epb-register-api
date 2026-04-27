module LodgementRules
  class ScottishRdsap
    def self.method_or_nil(adapter, method)
      Helper::ClassHelper.method_or_nil(adapter, method)
    end

    RULES = [
      {
        name: "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE VAL009",
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
        name: "INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE VAL010",
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
        name: "COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT VAL011",
        title:
          "Date of certificate declared is not the same as date of lodgement to the register",
        test:
          lambda do |adapter, _country_lookup = nil|
            completion_date = Date.parse(method_or_nil(adapter, :date_of_completion))

            completion_date == Date.today
          end,
      },
      {
        name: "PARTY_WALLS_ARE_NOT_APPLICABLE_FOR_DETACHED_PROPERTIES VAL001",
        title:
          "When the build form for a property is detached, party walls must be recorded as not applicable",
        test:
          lambda do |adapter, _country_lookup = nil|
            built_form = method_or_nil(adapter, :built_form)

            party_walls_construction = method_or_nil(adapter, :party_walls_construction)

            party_walls_exist = party_walls_construction.any? { |v| v != "NA" }

            if built_form == "1" && party_walls_exist
              false
            else
              true
            end
          end,
      },
      {
        name: "PARTY_WALLS_ARE_NOT_DEFINED_USING_CURRENT_SURVEY_INFORMATION_VAL003",
        title:
          "Party walls must be defined using current survey information",
        test:
          lambda do |adapter, _country_lookup = nil|
            party_walls_construction = method_or_nil(adapter, :party_walls_construction)

            party_walls_no_information = party_walls_construction.any? { |v| v != "NI" }

            if party_walls_no_information
              true
            else
              false
            end
          end,
      },
      {
        name: "TOTAL_FLOOR_AREA_LESS_THAN_30_VAL012",
        title:
          "Very small total floor area (<30) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            total_floor_area = method_or_nil(adapter, :total_floor_area)

            (total_floor_area.to_f > 30.0)
          end,
      },
      {
        name: "TOTAL_FLOOR_AREA_GREATER_THAN_299_VAL013",
        title:
          "Very large total floor area (>299) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            total_floor_area = method_or_nil(adapter, :total_floor_area)

            (total_floor_area.to_f < 299.0)
          end,
      },
      {
        name: "PRIMARY_ENERGY_VALUE_LESS_THAN_50_VAL015",
        title:
          "Very low primary energy value (<50) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            primary_energy_use = method_or_nil(adapter, :primary_energy_use)

            (primary_energy_use.to_f > 50.0)
          end,
      },
      {
        name: "PRIMARY_ENERGY_VALUE_GREATER_THAN_849_VAL016",
        title:
          "Very high primary energy value (>849) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            primary_energy_use = method_or_nil(adapter, :primary_energy_use)

            (primary_energy_use.to_f < 849.0)
          end,
      },
      {
        name: "WALL_THICKNESS_GREATER_THAN_801_VAL004",
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
        name: "WALL_THICKNESS_LESS_THAN_140_NOT_PARK_HOME_OR_SYSTEM_BUILT_VAL006",
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

            if thin_walls
              false
            else
              true
            end
          end,
      },
      {
        name: "WALL_THICKNESS_LESS_THAN_230_WITH_CAVITY_VAL007",
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

            if thin_walls
              false
            else
              true
            end
          end,
      },
      {
        name: "WALL_THICKNESS_MEASURED_IS_N_BUT_WALL_THICKNESS_PRESENT_VAL008",
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

            if thin_walls
              false
            else
              true
            end
          end,
      },
      {
        name: "10_OR_MORE_HABITABLE_ROOMS_VAL002",
        title:
          "High number of habitable rooms - 10 or more",
        test:
          lambda do |adapter, _country_lookup = nil|
            habitable_room_count = method_or_nil(adapter, :habitable_room_count)

            (habitable_room_count.to_i < 9)
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
