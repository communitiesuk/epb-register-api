module UseCase
  class FetchDomesticEnergyAssessment
    class NotFoundException < Exception; end

    def initialize(domestic_energy_assessments_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
    end

    def execute(assessment_id)
      assessment = @domestic_energy_assessments_gateway.fetch(assessment_id)
      raise NotFoundException unless assessment

      current_energy_efficiency_rating = assessment[:current_energy_efficiency_rating]
      potential_energy_efficiency_rating = assessment[:potential_energy_efficiency_rating]

      assessment[:currentEnergyEfficiencyRatingBand] = get_energy_rating_band(current_energy_efficiency_rating)
      assessment[:potentialEnergyEfficiencyRatingBand] = get_energy_rating_band(potential_energy_efficiency_rating)

      assessment
    end

    private

    def get_energy_rating_band(number)
      case number
      when 1..20
        'g'
      when 21..38
        'f'
      when 39..54
        'e'
      when 55..68
        'd'
      when 69..80
        'c'
      when 81..91
        'b'
      when 92..100
        'a'
      end
    end

  end
end
