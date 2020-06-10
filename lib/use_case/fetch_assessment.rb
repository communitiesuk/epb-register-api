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
        green_deal_domain =
          Domain::GreenDealPlan.new(
            green_deal_plan_id: green_deal_data[:green_deal_plan_id],
            assessment_id: green_deal_data[:assessment_id],
            start_date: green_deal_data[:start_date],
            end_date: green_deal_data[:end_date],
            provider_name: green_deal_data[:provider_name],
            provider_telephone: green_deal_data[:provider_telephone],
            provider_email: green_deal_data[:provider_email],
            interest_rate: green_deal_data[:interest_rate],
            fixed_interest_rate: green_deal_data[:fixed_interest_rate],
            charge_uplift_amount: green_deal_data[:charge_uplift_amount],
            charge_uplift_date: green_deal_data[:charge_uplift_date],
            cca_regulated: green_deal_data[:cca_regulated],
            structure_changed: green_deal_data[:structure_changed],
            measures_removed: green_deal_data[:measures_removed],
            measures: [green_deal_data[:measures]],
            charges: [green_deal_data[:charges]],
            savings: [green_deal_data[:savings]],
          )
            .to_hash

        assessment[:green_deal_plan]
        return assessment.merge(green_deal_plan: green_deal_domain)
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
