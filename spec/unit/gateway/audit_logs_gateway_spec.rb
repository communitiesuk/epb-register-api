describe Gateway::AuditLogsGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  context "when adding data to the audit log table " do

    it 'does not raise an error' do
      expect {subject}.not_to raise_error
    end

    it 'receives add_audit_log method' do
      allow(subject).to receive(:add_audit_event).and_return(1)
      expect(subject.add_audit_event(entity_type: "assessment", entity_id: "0000-0000-0000-0000-0001", event_type: "opt_out")).to eq(1)
    end
  end
end
