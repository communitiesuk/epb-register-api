module UseCase
  class FetchAssessment
    class NotFoundException < StandardError; end

    def initialize(
      assessments_gateway, assessors_gateway, green_deal_plans_gateway
    )
      @assessments_gateway = assessments_gateway
      @assessors_gateway = assessors_gateway
      @green_deal_plans_gateway = green_deal_plans_gateway
    end

    def execute(assessment_id)
      assessment = @assessments_gateway.fetch(assessment_id)

      raise NotFoundException unless assessment

      assessment[:current_energy_efficiency_band] =
        get_energy_rating_band(assessment[:current_energy_efficiency_rating])
      assessment[:potential_energy_efficiency_band] =
        get_energy_rating_band(assessment[:potential_energy_efficiency_rating])

      assessor = @assessors_gateway.fetch(assessment[:scheme_assessor_id])

      assessment.delete(:scheme_assessor_id)
      assessment[:assessor] = assessor.to_hash

      green_deal_data = @green_deal_plans_gateway.fetch(assessment_id)

      unless green_deal_data.nil?
        assessment[:green_deal_plan]
        return assessment.merge(green_deal_plan: green_deal_data)
      end

      assessment
    end

  private

    def get_energy_rating_band(number)
      case number
      when 1..20
        "g"
      when 21..38
        "f"
      when 39..54
        "e"
      when 55..68
        "d"
      when 69..80
        "c"
      when 81..91
        "b"
      when 92..100
        "a"
      end
    end
  end
end
