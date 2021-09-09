describe Listener::NotifyAssessmentAddressIdUpdateToDataWarehouse do
  subject(:listener) { described_class.new(notify_use_case: notify_use_case) }

  let(:notify_use_case) { instance_spy(UseCase::NotifyAssessmentAddressIdUpdateToDataWarehouse) }

  let(:assessment_id) { "0000-1111-2222-3333-4444" }

  it "executes the notify use case" do
    listener.assessment_address_id_updated(assessment_id)

    expect(notify_use_case).to have_received(:execute).with(assessment_id: assessment_id)
  end
end
