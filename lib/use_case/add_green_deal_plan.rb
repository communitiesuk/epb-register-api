module UseCase
  class AddGreenDealPlan
    class AssessmentGoneException < StandardError
    end

    class AssessmentExpiredException < StandardError
    end

    class DuplicateException < StandardError
    end

    class InvalidTypeException < StandardError
    end

    class NotFoundException < StandardError
    end

    class InvalidFuelCode < StandardError
    end

    def initialize
      @assessments_gateway = Gateway::AssessmentsSearchGateway.new
      @green_deal_plan_gateway = Gateway::GreenDealPlansGateway.new
    end

    def execute(assessment_id, data)
      if @green_deal_plan_gateway.exists? data[:green_deal_plan_id]
        raise DuplicateException
      end

      assessments =
        @assessments_gateway.search_by_assessment_id assessment_id, false

      assessment = assessments.first

      raise NotFoundException unless assessment

      assessment = assessment.to_hash

      if %w[CANCELLED NOT_FOR_ISSUE].include? assessment[:status]
        raise AssessmentGoneException
      end

      raise AssessmentExpiredException if assessment[:date_of_expiry] < Time.now

      unless %w[RdSAP].include? assessment[:type_of_assessment]
        raise InvalidTypeException
      end

      fuel_codes = data[:savings].map { |saving| saving[:fuel_code] }

      unless @green_deal_plan_gateway.validate_fuel_codes?(fuel_codes)
        raise InvalidFuelCode,
              "One of [#{fuel_codes.join(', ')}] is not a valid fuel code"
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

      @green_deal_plan_gateway.add green_deal_plan, assessment_id

      @green_deal_plan_gateway.fetch(assessment_id).first
    end
  end
end
