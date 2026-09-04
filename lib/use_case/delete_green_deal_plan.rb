module UseCase
  class DeleteGreenDealPlan
    class NotFoundException < StandardError
    end

    def initialize(green_deal_plans_gateway:, event_broadcaster:)
      @green_deal_plans_gateway = green_deal_plans_gateway
      @event_broadcaster = event_broadcaster
    end

    def execute(plan_id)
      exists_in_scotland = @green_deal_plans_gateway.exists_in_scotland?(plan_id)

      unless exists_in_scotland || @green_deal_plans_gateway.exists?(plan_id)
        raise NotFoundException
      end

      assessment_ids = @green_deal_plans_gateway.fetch_assessment_ids(plan_id:, is_scottish: exists_in_scotland)

      @green_deal_plans_gateway.delete(plan_id)

      @event_broadcaster.broadcast(:green_deal_plan_deleted,
                                   green_deal_plan_id: plan_id,
                                   assessment_ids:,
                                   is_scottish: exists_in_scotland)
      {}
    end
  end
end
