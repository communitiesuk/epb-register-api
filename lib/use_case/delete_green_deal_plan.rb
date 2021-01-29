module UseCase
  class DeleteGreenDealPlan
    class NotFoundException < StandardError
    end

    def initialize
      @green_deal_plan_gateway = Gateway::GreenDealPlansGateway.new
    end

    def execute(plan_id)
      raise NotFoundException unless @green_deal_plan_gateway.exists?(plan_id)

      @green_deal_plan_gateway.delete(plan_id)

      {}
    end
  end
end
