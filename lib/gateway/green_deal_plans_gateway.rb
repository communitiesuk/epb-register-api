module Gateway
  class GreenDealPlansGateway
    class GreenDealPlans < ActiveRecord::Base; end

    def fetch(assessment_id)
      GreenDealPlans.find_by(assessment_id: assessment_id)
    end
  end
end
