describe UseCase::DeleteGreenDealPlan do
  subject(:use_case) do
    described_class.new(
      green_deal_plans_gateway: green_deal_plans_gateway,
      event_broadcaster: Events::Broadcaster.new,
    )
  end

  let(:green_deal_plans_gateway) { instance_spy(Gateway::GreenDealPlansGateway) }

  describe "event broadcasting" do
    around do |test|
      Events::Broadcaster.enable!
      test.run
      Events::Broadcaster.disable!
    end

    before do
      allow(green_deal_plans_gateway).to receive(:exists?).with("ABC123456ABC").and_return(true)
      allow(green_deal_plans_gateway).to receive(:delete)
      allow(green_deal_plans_gateway).to receive(:fetch_assessment_id).with({ plan_id: "ABC123456ABC" }).and_return("0000-0000-0000-0000-0000")
    end

    it "broadcasts green deal plan deleted event with assessment id and green deal plan id" do
      expect { use_case.execute("ABC123456ABC") }.to broadcast(
        :green_deal_plan_deleted,
        green_deal_plan_id: "ABC123456ABC",
        assessment_id: "0000-0000-0000-0000-0000",
      )
    end
  end
end
