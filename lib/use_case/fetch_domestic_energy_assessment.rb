module UseCase
  class FetchDomesticEnergyAssessment
    class NotFoundException < Exception; end

    def initialize(domestic_energy_assessments_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
    end

    def execute(assessment_id)
      assessment = @domestic_energy_assessments_gateway.fetch(assessment_id)

      raise NotFoundException unless assessment

      assessment
    end
  end
end
