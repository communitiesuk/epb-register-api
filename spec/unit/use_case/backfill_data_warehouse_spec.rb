describe UseCase::BackfillDataWarehouse do
  subject(:use_case) do
    described_class.new(backfill_gateway:, data_warehouse_queues_gateway:)
  end

  let(:backfill_gateway) { instance_double(Gateway::BackfillDataWarehouseGateway) }
  let(:data_warehouse_queues_gateway) { instance_double(Gateway::DataWarehouseQueuesGateway) }
  let(:start_date) { "2020-05-01" }
  let(:type_of_assessment) { "RdSAP" }

  before do
    allow($stdout).to receive(:puts)
    allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(%w[0000-0000-0000-0000-0000])
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue).with(any_args)

  end

  describe "#execute" do
    it "invokes without error" do
      expect { use_case.execute(start_date:, type_of_assessment:) }.not_to raise_error
    end

    it "raises an error when there are no assessments found with that rrn" do
      allow(backfill_gateway).to receive(:get_assessments_id).and_return([])
      expect { use_case.execute(start_date:, type_of_assessment:) }.to raise_error(Boundary::NoData)
    end

    it "raises an error if the end_date is before the start_date" do
      expect { use_case.execute(start_date: "2021-05-14", end_date: "2020-05-14", type_of_assessment:) }.to raise_error(Boundary::InvalidDate)
    end

    it "puts the data in the queue" do
      allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002])
      use_case.execute(start_date:, type_of_assessment:)
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:assessments, %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]).exactly(1).times
    end

    it "puts more than 500 assessments in the queue" do
      large_array = Array.new(501, "0000-0000-0000-0000-0000")
      allow(backfill_gateway).to receive(:get_assessments_id).with(any_args).and_return(large_array)
      use_case.execute(start_date:, type_of_assessment:)
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).exactly(2).times
    end


  end
end
