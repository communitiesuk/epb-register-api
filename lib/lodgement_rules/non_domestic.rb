module LodgementRules
  class NonDomestic
    def self.method_or_nil(adapter, method)
      Helper::ClassHelper.method_or_nil(adapter, method)
    end

    CURRENT_SBEM_VERSIONS = { england: "SBEM, v6.1", northern_ireland: "SBEM, v4.1", wales: "SBEM, v6.1.e", england_type_three: "SBEM, v5.6", wales_5_6: "SBEM, v5.6" }.freeze

    RULES = [
      {
        name: "DATES_CANT_BE_IN_FUTURE",
        title:
          '"Inspection-Date", "Registration-Date", "Issue-Date", "Effective-Date", "OR-Availability-Date", "Start-Date" and "OR-Assessment-Start-Date" must not be in the future',
        test:
          lambda do |adapter, _country_lookup = nil|
            dates =
              [
                method_or_nil(adapter, :date_of_assessment),
                method_or_nil(adapter, :date_of_registration),
                method_or_nil(adapter, :date_of_issue),
                method_or_nil(adapter, :effective_date),
                method_or_nil(adapter, :or_availability_date),
                method_or_nil(adapter, :or_assessment_start_date),
              ].compact + adapter.all_start_dates
            dates.none? { |date| Date.parse(date).future? }
          end,
      },
      {
        name: "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO",
        title:
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be more than 4 years ago',
        test:
          lambda do |adapter, _country_lookup = nil|
            dates = [
              method_or_nil(adapter, :date_of_assessment),
              method_or_nil(adapter, :date_of_registration),
              method_or_nil(adapter, :date_of_issue),
            ].compact

            dates.none? do |date|
              Date.parse(date).before?(Date.today << 12 * 4)
            end
          end,
      },
      {
        name: "FLOOR_AREA_CANT_BE_LESS_THAN_ZERO",
        title: '"Floor-Area" must be greater than 0',
        test:
          lambda do |adapter, _country_lookup = nil|
            floor_area = method_or_nil(adapter, :floor_area)
            floor_area.nil? || floor_area.to_f.positive?
          end,
      },
      {
        name: "EMISSION_RATINGS_MUST_NOT_BE_NEGATIVE",
        title: '"SER", "BER", "TER" and "TYR" must not be negative numbers',
        test:
          lambda do |adapter, _country_lookup = nil|
            [
              method_or_nil(adapter, :standard_emissions),
              method_or_nil(adapter, :building_emission_rate),
              method_or_nil(adapter, :target_emissions),
              method_or_nil(adapter, :typical_emissions),
            ].compact
              .map(&:to_f)
              .none?(&:negative?)
          end,
      },
      {
        name: "MUST_RECORD_TRANSACTION_TYPE",
        title: '"Transaction-Type" must not be equal to 7',
        test:
          lambda do |adapter, _country_lookup = nil|
            method_or_nil(adapter, :transaction_type).to_i != 7
          end,
      },
      {
        name: "MUST_RECORD_EPC_DISCLOSURE",
        title: '"EPC-Related-Party-Disclosure" must not be equal to 13',
        test:
          lambda do |adapter, _country_lookup = nil|
            method_or_nil(adapter, :epc_related_party_disclosure).to_i != 13
          end,
      },
      {
        name: "MUST_RECORD_ENERGY_TYPE",
        title: '"Energy-Type" must not be equal to 4',
        test:
          lambda do |adapter, _country_lookup = nil|
            adapter
              .all_energy_types
              .map(&:to_i)
              .none? { |energy_type| energy_type == 4 }
          end,
      },
      {
        name: "MUST_RECORD_REASON_TYPE",
        title: '"Reason-Type" must not be equal to 7',
        test:
          lambda do |adapter, _country_lookup = nil|
            reason_types = method_or_nil(adapter, :all_reason_types)
            return true unless reason_types

            reason_types.compact.select { |reason| reason == "7" }.empty?
          end,
      },
      {
        name: "MUST_RECORD_DEC_DISCLOSURE",
        title: '"DEC-Related-Party-Disclosure" must not be equal to 8',
        test:
          lambda do |adapter, _country_lookup = nil|
            disclosure = method_or_nil(adapter, :dec_related_party_disclosure)
            disclosure.nil? || disclosure != "8"
          end,
      },
      {
        name: "NOMINATED_DATE_TOO_LATE",
        title:
          '"Nominated-Date" must not be more than three months after "OR-Assessment-End-Date"',
        test:
          lambda do |adapter, _country_lookup = nil|
            current_nominated_date =
              method_or_nil(adapter, :current_assessment_date)
            or_end_date = method_or_nil(adapter, :or_assessment_end_date)
            return true unless current_nominated_date && or_end_date

            latest_nominated_date = Date.parse(or_end_date) >> 3
            Date.parse(current_nominated_date) <= latest_nominated_date
          end,
      },
      {
        name: "INVALID_COUNTRY",
        title:
          "Property address must be in England, Wales, or Northern Ireland",
        test:
          # Unlike domestic lodgments non-domestic XML does not contain a country code
          lambda do |adapter, country_lookup = nil|
            country_code = method_or_nil(adapter, :country_code)
            if country_lookup.in_channel_islands? || country_lookup.in_isle_of_man? || (country_lookup.in_scotland? && !country_lookup.in_england?) || country_code == "SCT"
              false
            else
              true
            end
          end,
      },
      {
        name: "WRONG_SBEM_VERSION_FOR_REGION",
        title:
          "Correct versions are: Northern Ireland - SBEM 4.1, Wales - SBEM 6.1.e, England - SBEM 6.1",
        test:
          #  For non-domestic EPCs and recommendation reports (Report-Type is 3 or 4)
          #
          # If the address is in Northern Ireland (i.e. has "BT" postcode) then SBEM version must be "v4.1.h.0"
          # If the address has a postcode that is entirely in Wales then SBEM version must be "v6.1.b.0"
          # If the address has a postcode that is entirely in England and <Transaction-Type> is 1,2,4,5 or 6 then SBEM version must be "v6.1.b.0"
          # If the address has a postcode that is in  England and <Transaction-Type> is equal to 3 then SBEM version can be either "v5.6.b.0" or "v6.1.b.0"
          # If the address has a postcode that covers properties in both England and Wales then c version can be either "v5.6.b.0" or "v6.1.b.0"
          lambda do |adapter, country_lookup = nil|
            report_type = method_or_nil(adapter, :report_type)
            if %w[3 4].include? report_type # This is a CEPC or CEPC-RR
              calc_tool = method_or_nil(adapter, :calculation_tool)
              building_level = method_or_nil(adapter, :building_level)
              transaction_type = method_or_nil(adapter, :transaction_type)
              if [3,4].include? building_level # Check SBEM software version for these
                return false if wrong_sbem_version_for_ni?(country_lookup, calc_tool)
                return false if unless_in_ni?(country_lookup, calc_tool, transaction_type)
                return false if wrong_sbem_version_for_wales?(country_lookup, calc_tool, transaction_type)
                return false if wrong_sbem_version_for_england?(country_lookup, calc_tool, transaction_type)
                return false if no_known_sbem_version_for_england_and_wales_transaction_type_three?(country_lookup, calc_tool, transaction_type)
              else
                #  Level 5 - DSM rules go in here once we know them
                return true
              end
            end
            true
          end,
      },
      {
        name: "INSPECTION_DATE_LATER_THAN_REGISTRATION_DATE",
        title:
          'The "Registration-Date" must be equal to or later than "Inspection-Date"',
        test:

          lambda do |adapter, _country_lookup = nil|
            dates = [
              Date.parse(method_or_nil(adapter, :date_of_assessment)),
              # Inspection-Date
              Date.parse(method_or_nil(adapter, :date_of_registration)),
              # Registration-Date
            ]

            (dates[0] <= dates[1])
          end,
      },
    ].freeze

    def self.wrong_sbem_version_for_ni?(lookup, calc_tool)
      true if lookup.in_northern_ireland? && !(calc_tool.include? CURRENT_SBEM_VERSIONS[:northern_ireland])
    end

    def self.unless_in_ni?(lookup, calc_tool, transaction_type)
      true if (calc_tool.include? CURRENT_SBEM_VERSIONS[:northern_ireland]) && !lookup.in_northern_ireland? && transaction_type != "3"
    end

    def self.wrong_sbem_version_for_wales?(lookup, calc_tool, transaction_type)
      true if (lookup.in_wales? && !lookup.in_england?) && !((calc_tool.include? CURRENT_SBEM_VERSIONS[:wales]) || (calc_tool.include? CURRENT_SBEM_VERSIONS[:wales_5_6])) && transaction_type != "3"
    end

    def self.wrong_sbem_version_for_england?(lookup, calc_tool, transaction_type)
      true if (calc_tool.include? CURRENT_SBEM_VERSIONS[:england_type_three]) && lookup.in_england? && transaction_type != "3"
    end

    def self.no_known_sbem_version_for_england_and_wales_transaction_type_three?(lookup, calc_tool, transaction_type)
      true if (lookup.in_wales? || lookup.in_england?) && transaction_type == "3" && CURRENT_SBEM_VERSIONS.values.none? { |sbem_version| calc_tool.include? sbem_version }
    end

    def validate(xml_adaptor, country_lookup)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor, country_lookup) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
