describe UseCase::SaveAuditEvent do
  subject(:use_case) { described_class.new(gateway) }

  let(:gateway) do
    instance_double(Gateway::AuditLogsGateway)
  end

  let(:domain_object) do
    Domain::AuditEvent.new(entity_type: :assessment, entity_id: "0000-0000-0000-0000-0001", event_type: :opt_out)
  end

  before do
    allow(gateway).to receive(:add_audit_event)
  end

  it "instantiates the class without error" do
    expect { use_case }.not_to raise_error
  end

  it "calls the correct gateway method" do
    use_case.execute(domain_object)
    expect(gateway).to have_received(:add_audit_event).with(domain_object).exactly(1).times
  end

  it "raises a error if the argument passed in not the the correct domian object" do
    expect { use_case.execute("domain_object") }.to raise_error(ArgumentError)
    expect { use_case.execute(gateway) }.to raise_error(ArgumentError)
  end
end
