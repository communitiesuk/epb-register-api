describe "reload queues rake" do
  include RSpecRegisterApiServiceMixin
  before do
    allow($stdout).to receive(:puts)
    Timecop.freeze(2026, 2, 22, 14, 32, 0)
    allow(ApiFactory).to receive_messages(data_warehouse_queues_gateway: data_warehouse_queues_gateway)
    allow(data_warehouse_queues_gateway).to receive(:push_to_queue)
    allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_return(unmatched_assessments)
    OauthStub.token
    WebMock.stub_request(:post, "http://test-addressing.gov.uk/match-address").to_return(status: 200, body: "", headers: {})
    EnvironmentStub.with("NUMBER_HOURS_BEFORE", "3")
    real_gateway = Gateway::AuditLogsGateway.new
    event_types.each do |event_type|
      assessment_ids.each do |assessment_id|
        real_gateway.add_audit_event(Domain::AuditEvent.new(entity_type: :assessment, entity_id: assessment_id, event_type: event_type[:type].to_sym))
      end
    end
  end

  after do
    allow(Helper::AddressMatchAssessment).to receive(:find_unmatched_assessments).and_call_original
  end

  after(:all) do
    Timecop.return
    EnvironmentStub.remove(%w[NUMBER_HOURS_BEFORE])
  end

  let(:unmatched_assessments) do
    [{ "assessment_id" => "0000-0000-0000-0000-0001",
       "address_line1" => "some line",
       "address_line2" => "some area",
       "address_line3" => "",
       "address_line4" => "",
       "postcode" => "SW1A 2AA",
       "town" => "WHITBURY" }]
  end

  let(:start_date) do
    Time.now.utc - 3.hours
  end

  let(:assessment_ids) do
    %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0004]
  end

  let(:rake) { get_task("oneoff:reload_queues") }
  let(:event_types) do
    [{ type: "lodgement", queue: :assessments_backfill },
     { type: "address_id_updated", queue: :assessments_address_update },
     { type: "cancelled", queue: :cancelled },
     { type: "opt_out", queue: :opt_outs }]
  end

  let(:data_warehouse_queues_gateway) { instance_double(Gateway::DataWarehouseQueuesGateway) }

  context "when calling the rake" do
    before do
      rake.invoke
    end

    it "calls gateway to put that data into the correct queue" do
      event_types.each do |i|
        assessment_ids.each do |assessment_id|
          expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).with(i[:queue], assessment_id).once
        end
      end
    end

    it "calls executes address match rake" do
      expect { get_task("oneoff:address_match_assessments").invoke }.to output(/Starting address matching backfill/).to_stdout
    end

    it "the address match rake receives the correct date range" do
      expect(Helper::AddressMatchAssessment).to have_received(:find_unmatched_assessments).with(date_from: start_date.to_date.to_s, date_to: Time.now.to_date.to_s, is_scottish: false, skip_existing: nil)
    end

    it "passes queue name validation when pushing to redis" do
      redis = instance_double(Redis)
      allow(redis).to receive(:lpush)
      real_gateway = Gateway::DataWarehouseQueuesGateway.new(redis_client: redis)
      allow(ApiFactory).to receive_messages(data_warehouse_queues_gateway: real_gateway)

      Rake::Task["oneoff:reload_queues"].reenable
      rake.invoke

      event_types.each do |i|
        assessment_ids.each do |assessment_id|
          expect(redis).to have_received(:lpush).with(i[:queue].to_s, assessment_id).once
        end
      end
    end
  end

  context "when no RRNs are found for an event type" do
    before do
      ActiveRecord::Base.connection.execute("DELETE FROM audit_logs WHERE event_type = 'opt_out'")
      rake.invoke
    end

    it "does not push onto the queue for that event" do
      expect(data_warehouse_queues_gateway).to have_received(:push_to_queue).exactly(9).times
      expect(data_warehouse_queues_gateway).not_to have_received(:push_to_queue).with(:opt_out, anything)
    end
  end
end
