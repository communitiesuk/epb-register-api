describe UseCase::SaveDailyAssessmentsStats do
  subject(:use_case) do
    described_class.new(gateway)
  end

  let(:gateway) do
    instance_double(Gateway::AssessmentStatisticsGateway)
  end

  context "when saving statistics data to the database" do
    before do
      allow(gateway).to receive(:save)
    end

    it "loads the class without error" do
      expect { use_case }.not_to raise_error
    end
  end
end
