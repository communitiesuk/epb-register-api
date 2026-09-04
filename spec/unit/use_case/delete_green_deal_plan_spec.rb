describe UseCase::DeleteGreenDealPlan do
  subject(:use_case) do
    described_class.new(
      green_deal_plans_gateway:,
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

    context "when the plan being deleted is not Scottish" do
      before do
        allow(green_deal_plans_gateway).to receive(:exists_in_scotland?).with("ABC123456ABC").and_return(false)
        allow(green_deal_plans_gateway).to receive(:exists?).with("ABC123456ABC").and_return(true)
        allow(green_deal_plans_gateway).to receive(:delete)
        allow(green_deal_plans_gateway).to receive(:fetch_assessment_ids).with({ plan_id: "ABC123456ABC", is_scottish: false }).and_return(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001])
      end

      it "broadcasts green deal plan deleted event with assessment id and green deal plan id" do
        expect { use_case.execute("ABC123456ABC") }.to broadcast(
          :green_deal_plan_deleted,
          green_deal_plan_id: "ABC123456ABC",
          assessment_ids: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
          is_scottish: false,
        )
      end
    end

    context "when the plan being deleted is Scottish" do
      before do
        allow(green_deal_plans_gateway).to receive(:exists_in_scotland?).with("ABC123456ABC").and_return(true)
        allow(green_deal_plans_gateway).to receive(:delete)
        allow(green_deal_plans_gateway).to receive(:fetch_assessment_ids).with({ plan_id: "ABC123456ABC", is_scottish: true }).and_return(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001])
      end

      it "broadcasts green deal plan deleted event with assessment id and green deal plan id" do
        expect { use_case.execute("ABC123456ABC") }.to broadcast(
          :green_deal_plan_deleted,
          green_deal_plan_id: "ABC123456ABC",
          assessment_ids: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
          is_scottish: true,
        )
      end
    end
  end
end
