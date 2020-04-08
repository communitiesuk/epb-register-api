module UseCase
  class FetchDomesticEnergyAssessment
    class NotFoundException < StandardError; end

    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(assessment_id)
      assessment = @domestic_energy_assessments_gateway.fetch(assessment_id)

      raise NotFoundException unless assessment

      assessment[:current_energy_efficiency_band] =
        get_energy_rating_band(assessment[:current_energy_efficiency_rating])
      assessment[:potential_energy_efficiency_band] =
        get_energy_rating_band(assessment[:potential_energy_efficiency_rating])

      assessor = @assessors_gateway.fetch(assessment[:scheme_assessor_id])

      assessment.delete(:scheme_assessor_id)
      assessment[:assessor] = assessor.to_hash

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
