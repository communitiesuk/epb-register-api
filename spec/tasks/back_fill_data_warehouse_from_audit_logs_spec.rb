describe "backfill data warehouse from audit logs" do
  let(:rake) { get_task("data_export:backfill_data_warehouse_from_events") }

  let(:use_case) { instance_double(UseCase::BackfillDataWarehouseByEvents) }
  let(:valid_events) { Domain::AuditEvent.valid_assessment_types }

  before do
    allow(ApiFactory).to receive(:backfill_data_warehouse_by_events_use_case).and_return(use_case)
    allow(use_case).to receive(:execute).with(any_args).and_return []
    allow($stdout).to receive(:puts)
  end

  context "when calling the rake" do
    before do
      EnvironmentStub.with("start_date", "2020-05-04")
      EnvironmentStub.with("end_date", "2020-05-08")
    end

    after do
      EnvironmentStub.remove(%w[end_date start_date])
    end

    it "executes without error" do
      expect { rake.invoke }.not_to raise_error
    end

    it "the use case is executed for each event type ", :aggregate_failures do
      rake.invoke
      expect(use_case).to have_received(:execute).with(event_type: "opt_out", start_date: "2020-05-04", end_date: "2020-05-08").exactly(1).times
      expect(use_case).to have_received(:execute).with(event_type: "opt_in", start_date: "2020-05-04", end_date: "2020-05-08").exactly(1).times
      expect(use_case).to have_received(:execute).with(event_type: "cancelled", start_date: "2020-05-04", end_date: "2020-05-08").exactly(1).times
    end
  end

  context "when calling the rake with no start date" do
    it "raise an Boundary::ArgumentMissing error" do
      EnvironmentStub.remove(%w[start_date])
      expect { rake.invoke }.to raise_error Boundary::ArgumentMissing
    end
  end

  context "when there is no data for one of the event types" do
    let(:use_case_opt_out) { instance_double(UseCase::BackfillDataWarehouseByEvents) }
    let(:use_case_opt_in) { instance_double(UseCase::BackfillDataWarehouseByEvents) }
    let(:use_case_cancelled) { instance_double(UseCase::BackfillDataWarehouseByEvents) }

    let(:start_date) do
      "2020-05-04"
    end
    let(:end_date) do
      "2020-05-31"
    end

    before do
      EnvironmentStub.with("start_date", start_date)
      EnvironmentStub.with("end_date", end_date)
      allow(ApiFactory).to receive(:backfill_data_warehouse_by_events_use_case).and_return(use_case_opt_out, use_case_opt_in, use_case_cancelled)
      allow(use_case_opt_out).to receive(:execute).with(event_type: "opt_out", start_date:, end_date:).and_return []
      allow(use_case_opt_in).to receive(:execute).with(event_type: "opt_in", start_date:, end_date:).and_raise Boundary::NoData, "No data "
      allow(use_case_cancelled).to receive(:execute).with(event_type: "cancelled", start_date:, end_date:).and_return []
    end

    after do
      EnvironmentStub.remove(%w[end_date start_date])
    end

    it "prints an error message for the one that has no data" do
      expect { rake.invoke }.to output(/No data/).to_stdout
    end

    it "executes the next use case that has data" do
      rake.invoke
      expect(use_case_cancelled).to have_received(:execute).with(event_type: "cancelled", start_date:, end_date:)
    end
  end
end
