describe UseCase::SaveDailyAssessmentsStats do
  subject(:use_case) do
    described_class.new(assessment_statistics_gateway: statistics_gateway, assessments_gateway: assessments_gateway)
  end

  let(:statistics_gateway) { instance_double(Gateway::AssessmentStatisticsGateway) }
  let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }

  context "when deriving the statistics for a given date" do
    before do
      allow(statistics_gateway).to receive(:save)
      allow(assessments_gateway).to receive(:fetch_assessments_by_date).and_return(
        [
          { "assessment_id" => "0000-0000-0000-0000", "assessment_type" => "RdSAP", "current_energy_rating": 58, "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0001", "assessment_type" => "SAP", "current_energy_rating": 50, "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0002", "assessment_type" => "SAP", "current_energy_rating": 30, "scheme_id": 2 },
          { "assessment_id" => "0000-0000-0000-0003", "assessment_type" => "SAP", "current_energy_rating": 50, "scheme_id": 2 },
          { "assessment_id" => "0000-0000-0000-0003", "assessment_type" => "SAP", "current_energy_rating": 89, "scheme_id": 2 },
        ],
      )
    end

    it "calculates the avarage and groups them by assessment type and scheme id" do
      expect(use_case.execute(date: "2021-10-25")).to eq(
        [
          {
            assessment_type: "RdSAP",
            assessments_count: 1,
            rating_average: 58,
            scheme_id: 1,
          },
          {
            assessment_type: "SAP",
            assessments_count: 1,
            rating_average: 50,
            scheme_id: 1,
          },
          {
            assessment_type: "SAP",
            assessments_count: 3,
            rating_average: 56,
            scheme_id: 2,
          },
        ],
      )
    end
  end
end
