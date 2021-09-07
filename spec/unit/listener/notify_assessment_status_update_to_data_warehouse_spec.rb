describe Listener::NotifyAssessmentStatusUpdateToDataWarehouse do
  subject(:listener) { described_class.new(notify_use_case: notify_use_case) }

  let(:notify_use_case) { instance_spy(UseCase::NotifyAssessmentStatusUpdateToDataWarehouse) }

  let(:assessment_id) { "0000-1111-2222-3333-4444" }

  describe "#assessment_status_update" do
    it "executes the notify use case when assesment is cancelled or marked not-for-issue" do
      listener.assessment_status_update(assessment_id)

      expect(notify_use_case).to have_received(:execute).with(assessment_id: assessment_id)
    end
  end
end
