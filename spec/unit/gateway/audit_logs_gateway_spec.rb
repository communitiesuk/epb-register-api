describe Gateway::AuditLogsGateway do
  subject(:gateway) { described_class.new }

  context "when adding data to the audit_logs log table " do
    let(:saved_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM audit_logs")
    end

    let(:domain_object) do
      Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0001", event_type: :opt_out)
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

    it "saves the correct data into the database for an another event type " do
      obj = Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0002", event_type: :opt_in)
      gateway.add_audit_event(obj)
      expect(saved_data).to match [a_hash_including({ "entity_type" => "assessment", "entity_id" => "0000-0000-0000-0000-0002", "event_type" => "opt_in" })]
    end
  end
end
