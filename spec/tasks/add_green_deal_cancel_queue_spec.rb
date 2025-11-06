describe "add green deal assessments to the cancel queue rake" do
  include RSpecRegisterApiServiceMixin

  let(:task) { get_task("oneoff:add_green_deal_cancel_queue") }

  context "when calling the rake" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:data_warehouse_queues_gateway) { instance_double(Gateway::DataWarehouseQueuesGateway) }

    before do
      allow($stdout).to receive(:puts)
      allow(data_warehouse_queues_gateway).to receive(:push_to_queue)
      allow(ApiFactory).to receive(:data_warehouse_queues_gateway).and_return(data_warehouse_queues_gateway)
      add_super_assessor(scheme_id:)
      load_green_deal_data
      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1111",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABC654321DEF",
      )
      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1112",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABC654321RRR",
      )

      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1113",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABE654321RRR",
      )
    end

    it "runs the task without errors and prints the count" do
      expect { task.invoke }.to output(/pushed 3 assessments to the cancelled queue/).to_stdout
    end

    it "sends each found assessment to the cancelled queue" do
      task.invoke
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).exactly(3).times
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:cancelled, "0000-0000-0000-0000-1111")
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:cancelled, "0000-0000-0000-0000-1112")
    end
  end
end
