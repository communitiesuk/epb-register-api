describe Listener::NotifyAssessmentStatusUpdateToDataWarehouse do
  subject(:listener) { described_class.new(notify_use_case: notify_use_case) }

  let(:notify_use_case) { instance_spy(UseCase::NotifyAssessmentStatusUpdateToDataWarehouse) }

  let(:assessment_id) { "0000-1111-2222-3333-4444" }

  describe "#assessment_status_update" do
    context "when assessment is cancelled" do
      before do
        listener.assessment_cancelled assessment_id: assessment_id
      end

      it "executes the notify use case" do
        expect(notify_use_case).to have_received(:execute).with(assessment_id: assessment_id)
      end
    end

    context "when assessment is marked not for issue" do
      before do
        listener.assessment_marked_not_for_issue assessment_id: assessment_id
      end

      it "executes the notify use case" do
        expect(notify_use_case).to have_received(:execute).with(assessment_id: assessment_id)
      end
    end
  end
end
