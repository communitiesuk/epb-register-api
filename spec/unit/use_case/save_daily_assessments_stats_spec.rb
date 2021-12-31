describe UseCase::SaveDailyAssessmentsStats do
  subject(:use_case) do
    described_class.new(statistics_gateway)
  end

  let(:statistics_gateway) { instance_double(Gateway::AssessmentStatisticsGateway) }

  context "when invoking the use case to insert stats" do
    before do
      allow(statistics_gateway).to receive(:save_daily_stats)
    end

    it "executes without error" do
      expect { use_case.execute(date: date_today, assessment_types: %w[RdSAP SAP CEPC]) }.not_to raise_error
    end

    it "calls the save method just once" do
      use_case.execute(date: date_today, assessment_types: %w[RdSAP SAP CEPC])
      expect(statistics_gateway).to have_received(:save_daily_stats).with({ date: date_today, assessment_types: %w[RdSAP SAP CEPC] }).exactly(1).times
    end
  end
end
