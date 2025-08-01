module UseCase
  class PatchGreenDealPlan
    class NotFoundException < StandardError
    end

    def initialize(
      green_deal_plans_gateway:,
      event_broadcaster:
    )
      @green_deal_plans_gateway = green_deal_plans_gateway
      @event_broadcaster = event_broadcaster
    end

    def execute(json:)
      green_deal_plan_id = json[:green_deal_plan_id]
      unless @green_deal_plans_gateway.exists?(green_deal_plan_id)
        raise NotFoundException
      end

      end_date = json[:end_date]
      charges = json[:charges]
      @green_deal_plans_gateway.update_end_date_and_charges(green_deal_plan_id:, end_date:, charges:)

      @event_broadcaster.broadcast(:green_deal_plan_updated,
                                   green_deal_plan_id: green_deal_plan_id,
                                   assessment_ids: assessment_ids_for_gdp(green_deal_plan_id))
    end

  private

    def assessment_ids_for_gdp(plan_id)
      @green_deal_plans_gateway.fetch_assessment_ids(plan_id:)
    end
  end
end
