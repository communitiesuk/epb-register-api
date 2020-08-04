module LodgementRules
  class NonDomestic
    RULES = [
      {
        name: "INSPECTION_REGISTRATION_ISSUE_DATE",
        message:
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be in the future and must not be more than 4 years ago',
        test: lambda do |adaptor|
          dates = [
            adaptor.date_of_assessment,
            adaptor.date_of_registration,
            adaptor.date_of_issue,
          ]

          failed_rules =
            dates.select do |date|
              Date.parse(date).future? ||
                Date.parse(date).before?(Date.today - (365.25 * 4))
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
