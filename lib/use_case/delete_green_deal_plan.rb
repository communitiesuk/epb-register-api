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

      assessment_id = @green_deal_plans_gateway.fetch_assessment_id(plan_id: plan_id)

      @green_deal_plans_gateway.delete(plan_id)

      @event_broadcaster.broadcast(:green_deal_plan_deleted,
                                   green_deal_plan_id: plan_id,
                                   assessment_id: assessment_id)
      {}
    end
  end
end
