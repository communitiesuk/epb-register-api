module LodgementRules
  class NonDomestic
    RULES = [
      {
        name: "DATES_CANT_BE_IN_FUTURE",
        message:
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be in the future',
        test: lambda do |adaptor|
          dates = [
            adaptor.date_of_assessment,
            adaptor.date_of_registration,
            adaptor.date_of_issue,
            adaptor.effective_date
          ]

          failed_rules = dates.select { |date| Date.parse(date).future? }

          failed_rules.empty?
        end,
      },
      {
        name: "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO",
        message:
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be more than 4 years ago',
        test: lambda do |adaptor|
          dates = [
            adaptor.date_of_assessment,
            adaptor.date_of_registration,
            adaptor.date_of_issue,
          ]

          failed_rules =
            dates.select do |date|
              Date.parse(date).before?(Date.today << 12 * 4)
            end

          failed_rules.empty?
        end,
      },
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], message: error[:message] } }
    end
  end
end
