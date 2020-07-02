module UseCase
  class AddGreenDealPlan
    class NotFoundException < StandardError; end
    class AssessmentGoneException < StandardError; end
    class InvalidTypeException < StandardError; end

    def initialize
      @assessments_gateway = Gateway::AssessmentsGateway.new
      @green_deal_plans_gateway = Gateway::GreenDealPlansGateway.new
    end

    def execute(assessment_id, data)
      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, false

      assessment = assessments.first

      raise NotFoundException unless assessment

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment.to_hash[:status]
        raise AssessmentGoneException
      end

      unless %w[RdSAP].include? assessment.to_hash[:type_of_assessment]
        raise InvalidTypeException
      end

      green_deal_plan =
        Domain::GreenDealPlan.new(
          green_deal_plan_id: data[:green_deal_plan_id],
          start_date: data[:start_date],
          end_date: data[:end_date],
          provider_name: data.dig(:provider_details, :name),
          provider_email: data.dig(:provider_details, :email),
          provider_telephone: data.dig(:provider_details, :telephone),
          cca_regulated: data[:cca_regulated],
          structure_changed: data[:structure_changed],
          measures_removed: data[:measures_removed],
          charge_uplift_amount: data.dig(:charge_uplift, :amount),
          charge_uplift_date: data.dig(:charge_uplift, :date),
          interest_rate: data.dig(:interest, :rate),
          fixed_interest_rate: data.dig(:interest, :fixed),
          measures: data[:measures],
          charges: data[:charges],
          savings: data[:savings],
        )

      @green_deal_plans_gateway.add green_deal_plan

      green_deal_plan
    end
  end
end
