describe UseCase::PatchGreenDealPlan do
  subject(:use_case) do
    described_class.new(
      green_deal_plans_gateway: gateway,
      event_broadcaster: Events::Broadcaster.new,
    )
  end

  let(:gateway) { instance_double Gateway::GreenDealPlansGateway }

  describe "#execute" do
    before do
      allow(gateway).to receive(:update_end_date_and_charges)
      allow(gateway).to receive(:exists?)
      allow(gateway).to receive(:fetch_assessment_ids)
    end

    context "when a green deal plan exists" do
      let(:existent_plan_id) { "ABC123456ABC" }

      let(:json) do
        {
          green_deal_plan_id: existent_plan_id,
          end_date: "2025-01-01",
          charges: [{ "end_date" => "2033-03-29", "sequence" => 0, "start_date" => "2020-03-29", "daily_charge" => 0.7 }],
        }
      end

      let(:args) do
        {
          green_deal_plan_id: existent_plan_id,
          end_date: "2025-01-01",
          charges: [{ "end_date" => "2033-03-29", "sequence" => 0, "start_date" => "2020-03-29", "daily_charge" => 0.7 }],
        }
      end

      before do
        allow(gateway).to receive(:exists?).with(existent_plan_id).and_return(true)
        use_case.execute(json:)
      end

      it "checks the green deal plan id provided exists" do
        expect(gateway).to have_received(:exists?).with(existent_plan_id)
      end

      it "calls the gateway to update the charges with the correct arguments" do
        expect(gateway).to have_received(:update_end_date_and_charges).with(**args)
      end
    end

    context "when a green deal plan does not exist" do
      let(:non_existent_plan_id) { "ABC123456ABQ" }

      before do
        allow(gateway).to receive(:exists?).with(non_existent_plan_id).and_return(false)
      end

      it "raises error when green deal plan id passed in does not exist" do
        json = {
          green_deal_plan_id: non_existent_plan_id,
          end_date: "2025-01-01",
          charges: [{ "end_date" => "2033-03-29", "sequence" => 0, "start_date" => "2020-03-29", "daily_charge" => 0.7 }],
        }
        expect { use_case.execute(json: json) }.to raise_error UseCase::PatchGreenDealPlan::NotFoundException
      end
    end

    describe "event broadcasting" do
      around do |test|
        Events::Broadcaster.enable!
        test.run
        Events::Broadcaster.disable!
      end

      before do
        allow(gateway).to receive(:exists?).with("ABC123456ABC").and_return(true)
        allow(gateway).to receive(:fetch_assessment_ids).with({ plan_id: "ABC123456ABC" }).and_return(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001])
      end

      it "broadcasts green deal plan changed event with assessment id and green deal plan id" do
        json = {
          green_deal_plan_id: "ABC123456ABC",
          end_date: "2025-01-01",
          charges: [{ "end_date" => "2033-03-29", "sequence" => 0, "start_date" => "2020-03-29", "daily_charge" => 0.7 }],
        }

        expect { use_case.execute(json: json) }.to broadcast(
          :green_deal_plan_updated,
          green_deal_plan_id: "ABC123456ABC",
          assessment_ids: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
        )
      end
    end
  end
end
