module Gateway
  class GreenDealPlansGateway
    class GreenDealPlans < ActiveRecord::Base; end

    def fetch(assessment_id)
      GreenDealPlans.find_by(green_deal_plan_id: assessment_id)
    end
  end
end
