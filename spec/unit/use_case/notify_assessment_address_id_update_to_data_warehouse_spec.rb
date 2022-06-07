describe UseCase::NotifyAssessmentAddressIdUpdateToDataWarehouse do
  describe "#execute" do
    subject(:use_case) { described_class.new(redis_gateway:) }

    let(:redis_gateway) { instance_spy(Gateway::RedisGateway) }

    let(:assessment_id) { "0000-1111-2222-3333-4444" }

    before { allow(redis_gateway).to receive(:push_to_queue) }

    it "calls down to the redis gateway to push to the queue" do
      use_case.execute(assessment_id:)

      expect(redis_gateway).to have_received(:push_to_queue).with(:assessments, assessment_id)
    end

    context "when the gateway is unable to push and raises an error" do
      before do
        allow(redis_gateway).to receive(:push_to_queue).and_raise(Gateway::RedisGateway::PushFailedError)
      end

      it "raises a could not complete error" do
        expect { use_case.execute(assessment_id:) }.to raise_error(UseCase::NotifyAssessmentAddressIdUpdateToDataWarehouse::CouldNotCompleteError)
      end
    end
  end
end
