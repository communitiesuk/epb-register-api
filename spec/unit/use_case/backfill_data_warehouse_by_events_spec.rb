describe UseCase::BackfillDataWarehouseByEvents do
  subject(:use_case) { described_class.new(audit_logs_gateway:, data_warehouse_queues_gateway:) }

  let(:audit_logs_gateway) { instance_double(Gateway::AuditLogsGateway) }
  let(:data_warehouse_queues_gateway) { instance_double(Gateway::DataWarehouseQueuesGateway) }

  before do
    allow(audit_logs_gateway).to receive(:fetch_assessment_ids).and_return(data)
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue).with(any_args)
  end

  context "when extracting RRNs from audit event logs for opt out" do
    let(:data) do
      %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
    end

    before do
      use_case.execute(event_type: "opt_out", start_date: Time.now.strftime("%Y-%m-%d"),
                       end_date: (Time.now + 1.day).strftime("%Y-%m-%d"))
    end

    it "calls the gateway" do
      expect(audit_logs_gateway).to have_received(:fetch_assessment_ids).exactly(1).times
    end

    it "pushes the returned data onto the opt out queue once for every 500 hundred items" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:opt_outs, %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]).exactly(1).times
    end
  end

  context "when extracting RRNs from audit event logs for opt ins" do
    let(:data) do
      %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
    end

    before do
      use_case.execute(event_type: "opt_in", start_date: Time.now.strftime("%Y-%m-%d"),
                       end_date: (Time.now + 1.day).strftime("%Y-%m-%d"))
    end

    it "pushes the returned data onto the opt out queue" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:opt_outs, %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]).exactly(1).times
    end
  end

  context "when extracting RRNs from audit event logs for cancelled" do
    let(:data) do
      %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
    end

    before do
      use_case.execute(event_type: "cancelled", start_date: Time.now.strftime("%Y-%m-%d"),
                       end_date: (Time.now + 1.day).strftime("%Y-%m-%d"))
    end

    it "pushes the returned data onto the opt out queue" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:cancelled, %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]).exactly(1).times
    end
  end

  context "when extracting RRNs from audit event logs for address_id_updated" do
    let(:data) do
      %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
    end

    before do
      use_case.execute(event_type: "address_id_updated", start_date: Time.now.strftime("%Y-%m-%d"),
                       end_date: (Time.now + 1.day).strftime("%Y-%m-%d"))
    end

    it "pushes the returned data onto the opt out queue" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(:assessments, %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]).exactly(1).times
    end
  end

  context "when there is no data" do
    let(:data) do
      %w[]
    end

    it "raises a no data error" do
      expect { use_case.execute(event_type: "opt_out", start_date: Time.now.strftime("%Y-%m-%d"), end_date: (Time.now + 1.day).strftime("%Y-%m-%d")) }.to raise_error(Boundary::NoData, /No assessments to export for type opt_out/)
    end
  end

  context "when dates are out of range" do
    let(:data) do
      %w[0000-0000-0000-0000-0001]
    end

    it "raises an invalid date error" do
      start_date = (Time.now + 1.day).strftime("%Y-%m-%d")
      end_date = Time.now.strftime("%Y-%m-%d")
      expect { use_case.execute(event_type: "opt_out", start_date:, end_date:) }.to raise_error(Boundary::InvalidDate)
    end
  end
end
