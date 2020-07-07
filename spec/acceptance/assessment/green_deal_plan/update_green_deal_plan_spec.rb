# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlan:UpdateGreenDealPlan" do
  include RSpecAssessorServiceMixin

  describe "update a Green Deal Plan" do
    context "when unauthenticated" do
      it "returns status 401" do
        update_green_deal_plan plan_id: "AD0000002312",
                               accepted_responses: [401],
                               authenticate: false
      end
    end

    context "when unauthorised" do
      it "returns status 403" do
        update_green_deal_plan plan_id: "AD0000002312",
                               accepted_responses: [403],
                               scopes: %w[wrong:scope]
      end
    end
  end
end
