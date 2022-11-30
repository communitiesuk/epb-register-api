describe UseCase::NotifyAssessmentStatusUpdateToDataWarehouse do
  describe "#execute" do
    subject(:use_case) { described_class.new(redis_gateway: data_warehouse_queues_gateway) }

    let(:data_warehouse_queues_gateway) { instance_spy(Gateway::DataWarehouseQueuesGateway) }

    let(:assessment_id) { "0000-1111-2222-3333-4444" }

    before { allow(data_warehouse_queues_gateway).to receive(:push_to_queue) }

    it "calls down to the redis gateway to push to the queue" do
      use_case.execute(assessment_id:)

      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:cancelled, assessment_id)
    end
  end
end
