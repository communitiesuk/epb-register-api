describe Listener::NotifyNewAssessmentToDataWarehouse do
  subject(:listener) { described_class.new(notify_use_case: notify_use_case) }

  let(:notify_use_case) { instance_spy(UseCase::NotifyNewAssessmentToDataWarehouse) }

  let(:assessment_id) { "0000-1111-2222-3333-4444" }

  context "when assessment_lodged notification is made" do
    before do
      listener.assessment_lodged assessment_id: assessment_id
    end

    it "executes the notify use case" do
      expect(notify_use_case).to have_received(:execute).with(assessment_id: assessment_id)
    end
  end
end
