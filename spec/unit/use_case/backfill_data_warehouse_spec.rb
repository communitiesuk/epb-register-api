describe UseCase::BackfillDataWarehouse do
  subject(:use_case) do
    described_class.new(backfill_gateway:, data_warehouse_queues_gateway:)
  end

  let(:backfill_gateway) { instance_double(Gateway::BackfillDataWarehouseGateway) }
  let(:data_warehouse_queues_gateway) { instance_double(Gateway::DataWarehouseQueuesGateway) }
  let(:rrn) { "0000-0000-0000-0000-0000" }
  let(:start_date) { "2020-05-01" }
  let(:rrn_date) { [{ "date_registered" => "2020-05-04 00:00:00 UTC" }] }
  let(:schema_type) { "RdSAP-Schema-20.0.0" }

  before do
    allow($stdout).to receive(:puts)
    allow(backfill_gateway).to receive(:get_rrn_date).and_return(rrn_date)
    allow(backfill_gateway).to receive(:count_assessments_to_export).and_return(1)
    allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(%w[0000-0000-0000-0000-0000])
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue).with(any_args)

    EnvironmentStub.with("dry_run", "false")
  end

  describe "#execute" do
    it "invokes without error" do
      expect { use_case.execute(rrn:, start_date:, schema_type:) }.not_to raise_error
    end

    it "uses the get_rrn_date method " do
      use_case.execute(rrn:, start_date:, schema_type:)
      expect(backfill_gateway).to have_received(:get_rrn_date).with(rrn)
    end

    it "raises an error when there are no assessments found with that rrn" do
      allow(backfill_gateway).to receive(:get_rrn_date).and_return([])
      expect { use_case.execute(rrn:, start_date:, schema_type:) }.to raise_error(Boundary::NoData)
    end

    it "raises an error if the rrn date_registered comes before the start_date" do
      allow(backfill_gateway).to receive(:get_rrn_date).and_return(rrn_date)
      start_date = "2020-05-14"
      expect { use_case.execute(rrn:, start_date:, schema_type:) }.to raise_error(Boundary::InvalidDate)
    end

    it "uses the count_assessments_to_export method with no data" do
      allow(backfill_gateway).to receive(:count_assessments_to_export).with(any_args).and_return(0)
      expect { use_case.execute(rrn:, start_date:, schema_type:) }.to raise_error(Boundary::NoData)
    end

    it "uses the get_assessments_id method" do
      use_case.execute(rrn:, start_date:, schema_type:)
      expect(backfill_gateway).to have_received(:get_assessments_id).with(rrn_date: "2020-05-04 00:00:00 UTC", start_date:, schema_type:)
    end

    it "puts the data in the queue" do
      allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002])
      use_case.execute(rrn:, start_date:, schema_type:)
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:assessments, %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]).exactly(1).times
    end

    it "puts more than 500 assessments in the queue" do
      large_array = Array.new(501, "0000-0000-0000-0000-0000")
      allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(large_array)
      use_case.execute(rrn:, start_date:, schema_type:)
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).exactly(2).times
    end

    context "when the dry run environment variable is set to true" do
      before do
        EnvironmentStub.with("dry_run", "true")
      end

      after do
        EnvironmentStub.with("dry_run", "false")
      end

      it "gives a count of the number of assessment as 3" do
        allow(backfill_gateway).to receive(:count_assessments_to_export).and_return(3)
        expect(use_case.execute(rrn:, start_date:, schema_type:)).to eq(3)
      end

      it "does not push data to the queue" do
        allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002])
        use_case.execute(rrn:, start_date:, schema_type:)
        expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).exactly(0).times
      end
    end
  end
end
