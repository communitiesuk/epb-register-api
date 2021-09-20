module UseCase
  class DeleteGreenDealPlan
    class NotFoundException < StandardError
    end

    def initialize(green_deal_plans_gateway:, event_broadcaster:)
      @green_deal_plans_gateway = green_deal_plans_gateway
      @event_broadcaster = event_broadcaster
    end

    def execute(plan_id)
      raise NotFoundException unless @green_deal_plans_gateway.exists?(plan_id)

      @green_deal_plans_gateway.delete(plan_id)

      {}
    end
  end
end
