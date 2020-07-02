# frozen_string_literal: true

describe "Acceptance::Assessment::GreenDealPlans" do
  include RSpecAssessorServiceMixin

  context "when unauthenticated" do
    it "returns status 401" do
      add_green_deal_plan "123-456", "body", [401], false
    end
  end

  context "when unauthorised" do
    it "returns status 401" do
      add_green_deal_plan "123-456", "body", [403], true, nil, %w[wrong:scope]
    end
  end

  context "when an assessment does not exist" do
    it "returns status 404" do
      add_green_deal_plan "123-456", "body", [404]
    end
  end
end
