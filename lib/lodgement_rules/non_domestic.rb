module LodgementRules
  class NonDomestic
    def self.method_or_nil(adapter, method)
      adapter.send(method)
    rescue NoMethodError
      nil
    end

    RULES = [
      {
        name: "DATES_CANT_BE_IN_FUTURE",
        title:
          'Inspection-Date", "Registration-Date", "Issue-Date", "Effective-Date", "OR-Availability-Date", "Start-Date" and "OR-Assessment-Start-Date" must not be in the future',
        test: lambda do |adapter|
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
        test: lambda do |adapter|
          dates = [
            method_or_nil(adapter, :date_of_assessment),
            method_or_nil(adapter, :date_of_registration),
            method_or_nil(adapter, :date_of_issue),
          ].compact

          dates.none? { |date| Date.parse(date).before?(Date.today << 12 * 4) }
        end,
      },
      {
        name: "FLOOR_AREA_CANT_BE_LESS_THAN_ZERO",
        title: '"Floor-Area" must be greater than 0',
        test: lambda do |adapter|
          adapter.all_floor_areas.map(&:to_i).all?(&:positive?)
        end,
      },
      {
        name: "EMISSION_RATINGS_MUST_NOT_BE_NEGATIVE",
        title: '"SER", "BER", "TER" and "TYR" must not be negative numbers',
        test: lambda do |adapter|
          [
            method_or_nil(adapter, :standard_emissions),
            method_or_nil(adapter, :building_emissions),
            method_or_nil(adapter, :target_emissions),
            method_or_nil(adapter, :typical_emissions),
          ].compact.map(&:to_f).none?(&:negative?)
        end,
      },
      {
        name: "MUST_RECORD_TRANSACTION_TYPE",
        title: '"Transaction-Type" must not be equal to 7',
        test: lambda do |adapter|
          method_or_nil(adapter, :transaction_type).to_i != 7
        end,
      },
      {
        name: "MUST_RECORD_EPC_DISCLOSURE",
        title: '"EPC-Related-Party-Disclosure" must not be equal to 13',
        test: lambda do |adapter|
          method_or_nil(adapter, :epc_related_party_disclosure).to_i != 13
        end,
      },
      {
        name: "MUST_RECORD_ENERGY_TYPE",
        title: '"Energy-Type" must not be equal to 4',
        test: lambda do |adapter|
          adapter.all_energy_types.map(&:to_i).none? do |energy_type|
            energy_type == 4
          end
        end,
      },
      {
        name: "MUST_RECORD_REASON_TYPE",
        title: '"Reason-Type" must not be equal to 7',
        test: lambda do |adapter|
          reason_types = method_or_nil(adapter, :all_reason_types)
          return true unless reason_types

          reason_types.compact.select { |reason| reason == "7" }.empty?
        end,
      },
      {
        name: "MUST_RECORD_DEC_DISCLOSURE",
        title: '"DEC-Related-Party-Disclosure" must not be equal to 8',
        test: lambda do |adapter|
          disclosure = method_or_nil(adapter, :dec_related_party_disclosure)
          disclosure.nil? || disclosure != "8"
        end,
      },
      {
        name: "NOMINATED_DATE_TOO_LATE",
        title:
          '"Nominated-Date" must not be more than three months after "OR-Assessment-End-Date"',
        test: lambda do |adapter|
          current_nominated_date =
            method_or_nil(adapter, :current_assessment_date)
          or_end_date = method_or_nil(adapter, :or_assessment_end_date)
          return true unless current_nominated_date && or_end_date

          latest_nominated_date = Date.parse(or_end_date) >> 3
          Date.parse(current_nominated_date).before?(latest_nominated_date)
        end,
      },
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
