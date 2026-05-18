describe "reload queues rake" do
  include RSpecRegisterApiServiceMixin
  before do
    allow($stdout).to receive(:puts)
    Timecop.freeze(2026, 2, 22, 14, 32, 0)
    allow(ApiFactory).to receive_messages(audit_logs_gateway: audit_logs_gateway, data_warehouse_queues_gateway: data_warehouse_queues_gateway)
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue)
    allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return(unmatched_assessments)
    OauthStub.token
    WebMock.stub_request(:post, "http://test-addressing.gov.uk/match-address").to_return(status: 200, body: "", headers: {})
    EnvironmentStub.with("NUMBER_HOURS_BEFORE", "3")
  end

  after(:all) do
    Timecop.return
    EnvironmentStub.remove(%w[NUMBER_HOURS_BEFORE])
  end

  let(:unmatched_assessments) {
    [{ 'assessment_id' => "0000-0000-0000-0000-0001", "address_line1" => "some line", "address_line2" => "some area", "address_line3" =>  "",
      "address_line4" => "", "postcode" => "SW1A 2AA", "town" => "WHITBURY" }]
  }

  let(:start_date) {
    Time.now - 3.hours
  }

  let(:assessment_ids) do
    %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0004]
  end

  let(:rake) { get_task("oneoff:reload_queues") }
  let(:event_types) do
    [{ type: "lodgement", queue: :assessments },
     { type: "address_id_updated", queue: :assessments_address_update },
     { type: "cancelled", queue: :cancelled },
     { type: "opt_out", queue: :opt_outs }]
  end

  let(:audit_logs_gateway) { instance_double(Gateway::AuditLogsGateway) }
  let(:data_warehouse_queues_gateway) { instance_double(Gateway::DataWarehouseQueuesGateway) }



  context "when calling the rake" do
    before do
      allow(audit_logs_gateway).to receive(:fetch_assessment_ids).and_return(assessment_ids)
      rake.invoke
    end

   it "calls the gateway to extract data from the audit logs" do
    event_types.each do |i|
      expect(audit_logs_gateway).to have_received(:fetch_assessment_ids).with(event_type: i[:type], start_date: start_date).once
    end
  end

  it "calls gateway to put that data into the correct queue" do
    event_types.each do |i|
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(i[:queue], assessment_ids).once
    end
  end

  it "calls executes address match rake" do
    expect { get_task("oneoff:address_match_assessments").invoke }.to output(/Starting address matching backfill/).to_stdout
  end

    it "the address match rake receives the correct date range" do
      expect(Helper::AddressMatchAssessment).to have_received(:find_unmatched_assessments).with(date_from: start_date.to_s, date_to: Time.now.to_s, is_scottish: false, skip_existing: nil )
    end

  end

  context "when no RRNs are found for an event type" do
    before do
      allow(audit_logs_gateway).to receive(:fetch_assessment_ids).and_return(assessment_ids)
      allow(audit_logs_gateway).to receive(:fetch_assessment_ids).with(event_type: "opt_out", start_date: start_date).and_return(nil)
      rake.invoke
    end

    it "does not push onto the queue for that event" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).exactly(3).times
      expect(data_warehouse_queues_gateway).not_to have_received(:push_to_queue).with(:opt_out, nil)
    end
  end

end
