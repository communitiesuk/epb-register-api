module LodgementRules
  class NonDomestic
    RULES = [
      {
        name: "DATES_CANT_BE_IN_FUTURE",
        message:
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be in the future',
        test: lambda do |adapter|
          dates = [
            adapter.date_of_assessment,
            adapter.date_of_registration,
            adapter.date_of_issue,
            adapter.effective_date,
            adapter.or_availability_date,
            adapter.or_assessment_start_date,
          ] + adapter.start_dates

          failed_rules = dates.select { |date| Date.parse(date).future? }

          failed_rules.empty?
        end,
      },
      {
        name: "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO",
        message:
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be more than 4 years ago',
        test: lambda do |adapter|
          dates = [
            adapter.date_of_assessment,
            adapter.date_of_registration,
            adapter.date_of_issue,
          ]

          failed_rules =
            dates.select do |date|
              Date.parse(date).before?(Date.today << 12 * 4)
            end

          failed_rules.empty?
        end,
      },
      {
          name: "FLOOR_AREA_CANT_BE_LESS_THAN_ZERO",
          message:
              '"Floor-Area" must be greater than 0',
          test: lambda do |adapter|
            adapter.all_floor_areas.map(&:to_i).select { |number| number.negative? }.empty?
          end,
      },
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], message: error[:message] } }
    end
  end
end
