describe UseCase::SaveAuditEvent do
  include RSpecRegisterApiServiceMixin

  subject(:use_case){ described_class.new(gateway)}

  let(:gateway) {
    instance_double(Gateway::AuditLogsGateway)
  }

  let(:domian_object) {
    Domain::AuditEvent.new(entity_type: "assessment", entity_id: "0000-0000-0000-0000-0001", event_type: "opt_out")
  }

  before do
    allow(gateway).to receive(:add_audit_event)
  end

  it 'instantiates the class without error' do
    expect{use_case}.not_to raise_error
  end

  it 'calls the execute method to save the audit event' do
    expect{use_case.execute(domian_object)}.not_to raise_error
  end

  end
