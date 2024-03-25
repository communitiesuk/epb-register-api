describe Gateway::AuditLogsGateway do
  subject(:gateway) { described_class.new }

  let(:domain_object) do
    Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0001", event_type: :opt_out)
  end

  describe "#add_audit_event" do
    context "when adding data to the audit_logs log table" do
      let(:saved_data) do
        ActiveRecord::Base.connection.exec_query("SELECT * FROM audit_logs")
      end

      it "does not raise an error" do
        expect { gateway }.not_to raise_error
      end

      it "saves the correct data into the database for an opted_out assessment" do
        gateway.add_audit_event(domain_object)
        expect(saved_data).to match [a_hash_including({ "entity_type" => "assessment", "entity_id" => "0000-0000-0000-0000-0001", "event_type" => "opt_out" })]
      end

      it "the date saved into the timestamp field is today" do
        gateway.add_audit_event(domain_object)
        expect(saved_data.first["timestamp"].strftime("%Y%m%d")).to eq(Time.now.strftime("%Y%m%d"))
      end

      it "saves the correct data into the database for an another event type" do
        obj = Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0002", event_type: :opt_in)
        gateway.add_audit_event(obj)
        expect(saved_data).to match [a_hash_including({ "entity_type" => "assessment", "entity_id" => "0000-0000-0000-0000-0002", "event_type" => "opt_in" })]
      end
    end
  end

  describe "#fetch_assessment_ids" do
    let(:valid_events) do
      Domain::AuditEvent.valid_assessment_types
    end

    before do
      gateway.add_audit_event(domain_object)
      gateway.add_audit_event(Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0002", event_type: :opt_in))
      gateway.add_audit_event(Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0003", event_type: :lodgement))
    end

    context "when there are 3 entries in the audit logs" do
      it "returns an array of the RRN that matches the event type" do
        start_date = Time.now - 1.day
        expect(gateway.fetch_assessment_ids(event_type: "opt_in", start_date:, end_date: Time.now + 1.day)).to eq(%w[0000-0000-0000-0000-0002])
        expect(gateway.fetch_assessment_ids(event_type: "cancelled", start_date:, end_date: Time.now + 1.day)).to eq([])
      end
    end

    context "when there is an additional older entry in the audit logs" do
      before do
        two_days_ago = Time.now - 2.day
        gateway.add_audit_event(Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0004", event_type: :opt_in))
        ActiveRecord::Base.connection.exec_query("UPDATE audit_logs SET timestamp = '#{two_days_ago}' WHERE entity_id = '0000-0000-0000-0000-0004' ")
      end

      it "does not return the rrn of older event" do
        start_date = Time.now - 1.day
        expect(gateway.fetch_assessment_ids(event_type: "opt_in", start_date:, end_date: Time.now + 1.day)).not_to include(%w[0000-0000-0000-0000-0004])
      end
    end
  end
end
