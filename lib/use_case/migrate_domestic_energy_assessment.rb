module UseCase
  class MigrateDomesticEnergyAssessment
    def initialize(domestic_energy_assessments_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
    end

    def check_improvements(improvements)
      sequences = improvements.map(&:sequence)

      unless sequences.include? 0
        raise ArgumentError.new('Sequences must contain 0')
      end
    end

    def execute(domestic_energy_assessment)
      check_improvements(domestic_energy_assessment.recommended_improvements)

      @domestic_energy_assessments_gateway.insert_or_update(
        domestic_energy_assessment
      )
      domestic_energy_assessment
    end
  end
end
