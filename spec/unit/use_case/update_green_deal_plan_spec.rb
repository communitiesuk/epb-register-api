describe UseCase::UpdateGreenDealPlan do
  subject(:use_case) do
    described_class.new(
      green_deal_plans_gateway: green_deal_plans_gateway,
      event_broadcaster: EventBroadcaster.new,
    )
  end

  let(:green_deal_plans_gateway) { instance_spy(Gateway::GreenDealPlansGateway) }
  let(:updated_plan_data) do
    {
      green_deal_plan_id: "ABC123456ABC",
      measures: [],
      charges: [],
      savings: [
        { fuel_code: "39", fuel_saving: 23_253, standing_charge_fraction: 0 },
      ],
    }
  end

  describe "event broadcasting" do
    around do |test|
      EventBroadcaster.enable!
      test.run
      EventBroadcaster.disable!
    end

    before do
      allow(green_deal_plans_gateway).to receive(:exists?).with("ABC123456ABC").and_return(true)
      allow(green_deal_plans_gateway).to receive(:validate_fuel_codes?).and_return(true)
      allow(green_deal_plans_gateway).to receive(:update)
      allow(green_deal_plans_gateway).to receive(:fetch_assessment_id).with({ plan_id: "ABC123456ABC" }).and_return("0000-0000-0000-0000-0000")
    end

    it "broadcasts green deal plan changed event with assessment id and green deal plan id" do
      expect { use_case.execute("ABC123456ABC", updated_plan_data) }.to broadcast(
        :green_deal_plan_updated,
        green_deal_plan_id: "ABC123456ABC",
        assessment_id: "0000-0000-0000-0000-0000",
      )
    end
  end
end
