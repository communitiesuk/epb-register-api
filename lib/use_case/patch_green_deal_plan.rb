module UseCase
  class PatchGreenDealPlan
    class NotFoundException < StandardError
    end

    def initialize(
      green_deal_plans_gateway:
    )
      @green_deal_plans_gateway = green_deal_plans_gateway
    end

    def execute(json:)
      green_deal_plan_id = json[:green_deal_plan_id]
      unless @green_deal_plans_gateway.exists?(green_deal_plan_id)
        raise NotFoundException
      end

      end_date = json[:end_date]
      charges = json[:charges]
      @green_deal_plans_gateway.update_end_date_and_charges(green_deal_plan_id:, end_date:, charges:)
    end
  end
end
