module LodgementRules
  class NonDomestic
    def self.method_or_nil(adapter, method)
      adapter.send(method)
    rescue NoMethodError
      nil
    end

    CURRENT_SBEM_VERSIONS = { england: "SBEM, v6.1.b.0", northern_ireland: "SBEM, v4.1.h.0", wales: "SBEM, v5.6.b.0" }.freeze

    WALES_ONLY_POSTCODE_PREFIXES = %w[CF
                                      SA
                                      CH5
                                      CH6
                                      CH7
                                      CH8
                                      LD1
                                      LD2
                                      LD3
                                      LD4
                                      LD5
                                      LD6
                                      LL15
                                      LL16
                                      LL17
                                      LL18
                                      LL19
                                      LL21
                                      LL22
                                      LL23
                                      LL24
                                      LL25
                                      LL26
                                      LL27
                                      LL28
                                      LL29
                                      LL3
                                      LL4
                                      LL5
                                      LL6
                                      LL7
                                      NP4
                                      NP8
                                      NP10
                                      NP11
                                      NP12
                                      NP13
                                      NP15
                                      NP18
                                      NP19
                                      NP20
                                      NP22
                                      NP23
                                      NP24
                                      NP26
                                      NP44
                                      SY16
                                      SY17
                                      SY18
                                      SY19
                                      SY20
                                      SY22
                                      SY23
                                      SY24
                                      SY25].freeze

    CROSS_BORDER_ENGLAND_AND_WALES_POSTCODE_PREFIXES =
      %w[CH1
         CH4
         HR2
         HR3
         HR5
         LD7
         LD8
         LL11
         LL12
         LL13
         LL14
         LL20
         NP7
         NP16
         NP25
         SY5
         SY10
         SY15
         SY21].freeze

    RULES = [
      {
        name: "DATES_CANT_BE_IN_FUTURE",
        title:
          '"Inspection-Date", "Registration-Date", "Issue-Date", "Effective-Date", "OR-Availability-Date", "Start-Date" and "OR-Assessment-Start-Date" must not be in the future',
        test:
          lambda do |adapter|
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
          lambda do |adapter|
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
          lambda do |adapter|
            floor_area = method_or_nil(adapter, :floor_area)
            floor_area.nil? || floor_area.to_f.positive?
          end,
      },
      {
        name: "EMISSION_RATINGS_MUST_NOT_BE_NEGATIVE",
        title: '"SER", "BER", "TER" and "TYR" must not be negative numbers',
        test:
          lambda do |adapter|
            [
              method_or_nil(adapter, :standard_emissions),
              method_or_nil(adapter, :building_emissions),
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
          lambda do |adapter|
            method_or_nil(adapter, :transaction_type).to_i != 7
          end,
      },
      {
        name: "MUST_RECORD_EPC_DISCLOSURE",
        title: '"EPC-Related-Party-Disclosure" must not be equal to 13',
        test:
          lambda do |adapter|
            method_or_nil(adapter, :epc_related_party_disclosure).to_i != 13
          end,
      },
      {
        name: "MUST_RECORD_ENERGY_TYPE",
        title: '"Energy-Type" must not be equal to 4',
        test:
          lambda do |adapter|
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
          lambda do |adapter|
            reason_types = method_or_nil(adapter, :all_reason_types)
            return true unless reason_types

            reason_types.compact.select { |reason| reason == "7" }.empty?
          end,
      },
      {
        name: "MUST_RECORD_DEC_DISCLOSURE",
        title: '"DEC-Related-Party-Disclosure" must not be equal to 8',
        test:
          lambda do |adapter|
            disclosure = method_or_nil(adapter, :dec_related_party_disclosure)
            disclosure.nil? || disclosure != "8"
          end,
      },
      {
        name: "NOMINATED_DATE_TOO_LATE",
        title:
          '"Nominated-Date" must not be more than three months after "OR-Assessment-End-Date"',
        test:
          lambda do |adapter|
            current_nominated_date =
              method_or_nil(adapter, :current_assessment_date)
            or_end_date = method_or_nil(adapter, :or_assessment_end_date)
            return true unless current_nominated_date && or_end_date

            latest_nominated_date = Date.parse(or_end_date) >> 3
            Date.parse(current_nominated_date) <= latest_nominated_date
          end,
      },
      {
        name: "WRONG_SBEM_VERSION_FOR_REGION",
        title:
          "Correct versions are: Northern Ireland - SBEM 4.1, Wales - SBEM 5.6, England - SBEM 6.1",
        test:
          #  For non-domestic EPCs and recommendation reports (Report-Type is 3 or 4)
          #
          # If the address is in Northern Ireland (i.e. has "BT" postcode) then SBEM version must be "v4.1.h.0"
          # If the address has a postcode that is entirely in Wales then SBEM version must be "v5.6.b.0"
          # If the address has a postcode that is entirely in England and <Transaction-Type> is 1,2,4,5 or 6 then SBEM version must be "v6.1.b.0"
          # If the address has a postcode that is entirely in England and <Transaction-Type> is equal to 3 then SBEM version can be either "v5.6.b.0" or "v6.1.b.0"
          # If the address has a postcode that covers properties in both England and Wales then SBEM version can be either "v5.6.b.0" or "v6.1.b.0"
          lambda do |adapter|
            report_type = method_or_nil(adapter, :report_type)
            if %w[3 4].include? report_type # This is a CEPC or CEPC-RR
              postcode = method_or_nil(adapter, :postcode)
              calc_tool = method_or_nil(adapter, :calculation_tool)
              building_level = method_or_nil(adapter, :building_level)
              if %w[3 4].include? building_level # Check SBEM software version for these
                if (postcode.start_with? "BT") && !(calc_tool.include? CURRENT_SBEM_VERSIONS[:northern_ireland])
                  return false
                elsif (calc_tool.include? CURRENT_SBEM_VERSIONS[:northern_ireland]) && !(postcode.start_with? "BT")
                  return false
                elsif postcode.start_with?(*WALES_ONLY_POSTCODE_PREFIXES) && !(calc_tool.include? CURRENT_SBEM_VERSIONS[:wales])
                  return false
                elsif (calc_tool.include? CURRENT_SBEM_VERSIONS[:wales]) && !postcode.start_with?(*WALES_ONLY_POSTCODE_PREFIXES, *CROSS_BORDER_ENGLAND_AND_WALES_POSTCODE_PREFIXES)
                  transaction_type = method_or_nil(adapter, :transaction_type)
                  return false unless transaction_type == "3"
                end
              else
                #  Level 5 - DSM rules go in here once we know them
                return true
              end
            end
            return true
          end,
      },
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
