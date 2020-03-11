module UseCase
  class MigrateDomesticEnergyAssessment
    def initialize(domestic_energy_assessments_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
    end

    def execute(domestic_energy_assessment)
      @domestic_energy_assessments_gateway.insert_or_update(
        domestic_energy_assessment
      )
      domestic_energy_assessment
    end
  end
end
