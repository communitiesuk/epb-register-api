module UseCase
  class UpdateGreenDealPlan
    class NotFoundException < StandardError
    end

    class PlanIdMismatchException < StandardError
    end

    class InvalidFuelCode < StandardError
    end

    def initialize
      @green_deal_plan_gateway = Gateway::GreenDealPlansGateway.new
    end

    def execute(plan_id, data)
      raise NotFoundException unless @green_deal_plan_gateway.exists? plan_id

      raise PlanIdMismatchException unless plan_id == data[:green_deal_plan_id]

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

      @green_deal_plan_gateway.update green_deal_plan, plan_id
    end
  end
end
