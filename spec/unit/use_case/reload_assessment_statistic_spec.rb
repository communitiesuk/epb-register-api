describe UseCase::ReloadAssessmentStatistics do
  let(:use_case) { described_class.new(gateway:) }
  let(:gateway) { instance_double(Gateway::AssessmentStatisticsGateway) }

  describe "#execute" do
    before do
      allow(gateway).to receive(:reload_data)
    end

    it "call the gateway to reload the data" do
      use_case.execute
      expect(gateway).to have_received(:reload_data)
    end
  end
end
