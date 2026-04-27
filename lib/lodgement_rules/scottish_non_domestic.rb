module LodgementRules
  class ScottishNonDomestic
    def self.method_or_nil(adapter, method)
      Helper::ClassHelper.method_or_nil(adapter, method)
    end

    RULES = [
      {
        name: "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE_VAL200",
        title:
          "Date of building assessment (inspection date) cannot be any later than date of lodgement of data to the register",
        test:
          lambda do |adapter, _country_lookup = nil|
            dates = [
              Date.parse(method_or_nil(adapter, :inspection_date)),
              # Inspection-Date
              Date.parse(method_or_nil(adapter, :completion_date)),
              # Completion-Date
            ]

            dates[0] <= dates[1]
          end,
      },
      {
        name: "INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE_VAL201",
        title:
          "Building assessment not completed recently; data used for lodgement is more than three months old",
        test:
          lambda do |adapter, _country_lookup = nil|
            inspection_date = Date.parse(method_or_nil(adapter, :inspection_date))

            completion_date = Date.parse(method_or_nil(adapter, :completion_date))

            limit_date = inspection_date >> 3

            completion_date <= limit_date
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
