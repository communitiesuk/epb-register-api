module UseCase
  class FetchAssessment
    class NotFoundException < StandardError; end

    def initialize(
      assessments_gateway,
      assessors_gateway,
      green_deal_plans_gateway,
      assessments_xml_gateway = false
    )
      @assessments_gateway = assessments_gateway
      @assessors_gateway = assessors_gateway
      @green_deal_plans_gateway = green_deal_plans_gateway
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(assessment_id, xml = false)
      assessment = @assessments_gateway.fetch(assessment_id)

      raise NotFoundException unless assessment

      return @assessments_xml_gateway.fetch(assessment_id) if xml

      assessor = @assessors_gateway.fetch(assessment.get(:scheme_assessor_id))

      assessment.set(:assessor, assessor)

      green_deal_data = @green_deal_plans_gateway.fetch(assessment_id)

      unless green_deal_data.nil?
        green_deal_domain = structure_green_deal_data(green_deal_data)

        assessment.set(:green_deal_plan, green_deal_domain)
      end

      assessment
    end

  private

    def structure_green_deal_data(green_deal_data)
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
        measures: green_deal_data[:measures],
        charges: green_deal_data[:charges],
        savings: green_deal_data[:savings],
      )
        .to_hash
    end
  end
end
