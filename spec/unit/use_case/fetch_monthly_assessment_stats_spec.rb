describe UseCase::FetchMonthlyAssessmentStats do
  context "when extracting month assessments report " do
    subject(:use_case) { described_class.new(stats_gateway) }

    let(:stats_gateway)  do
      instance_double(Gateway::AssessmentStatisticsGateway)
    end

    let(:data) do
      [{ "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP" }]
    end

    before do
      allow(stats_gateway).to receive(:fetch_monthly_stats).and_return(data)
    end

    it "loads the use case without error" do
      expect(use_case.execute).to eq(data)
    end
  end
end
