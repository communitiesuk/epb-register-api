module LodgementRules
  class ScottishSap
    def self.method_or_nil(adapter, method)
      Helper::ClassHelper.method_or_nil(adapter, method)
    end

    RULES = [
      {
        name: "SCOTLAND_INSPECTION_DATE_LATER_THAN_COMPLETION_DATE_VAL100",
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
        name: "SCOTLAND_INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE_VAL101",
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
        name: "SCOTLAND_COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT_VAL102",
        title:
          "Date of certificate declared is not the same as date of lodgement to the register",
        test:
          lambda do |adapter, _country_lookup = nil|
            completion_date = Date.parse(method_or_nil(adapter, :date_of_completion))

            completion_date == Date.today
          end,
      },
      {
        name: "SCOTLAND_TOTAL_FLOOR_AREA_GREATER_THAN_450_VAL103",
        title:
          "Very large total floor area (>450) reported",
        test:
          lambda do |adapter, _country_lookup = nil|
            total_floor_area = method_or_nil(adapter, :total_floor_area)

            (total_floor_area.to_f < 450.0)
          end,
      },
      {
        name: "SCOTLAND_BOTH_MAIN_HEATING_INDEX_NUMBER_AND_MAIN_HEATING_CODE_MISSING_VAL104",
        title:
          "Neither Main-Heating-Index-Number nor Main-Heating-Code recorded for this dwelling",
        test:
          lambda do |adapter, _country_lookup = nil|
            main_heating_types = method_or_nil(adapter, :main_heating_types)

            both_missing = main_heating_types&.any? do |hash|
              hash[:main_heating_code].nil? && hash[:main_heating_index_number].nil?
            end

            !both_missing
          end,
      },
      {
        name: "SCOTLAND_CONSTRUCTION_YEAR_MISSING_FROM_BUILDING_PART_VAL106",
        title:
          "No construction year defined for dwelling part",
        test:
          lambda do |adapter, _country_lookup = nil|
            construction_years = method_or_nil(adapter, :construction_years)

            !construction_years&.any?(&:nil?)
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
