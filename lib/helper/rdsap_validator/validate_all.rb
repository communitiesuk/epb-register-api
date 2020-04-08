module Helper
  module RdsapValidator
    class ValidateAll
      ALL_RULES = [Helper::RdsapValidator::SuggestedImprovementSequence.new]

      def validate(domestic_energy_assessment)
        errors = []

        ALL_RULES.each do |rule|
          unless rule.validates?(domestic_energy_assessment)
            errors << { rule: rule.class.to_s, description: rule.description }
          end
        end
        errors
      end
    end
  end
end
