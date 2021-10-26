describe UseCase::SaveDailyAssessmentsStats do
  subject(:use_case) do
    described_class.new(assessment_statistics_gateway: statistics_gateway, assessments_gateway: assessments_gateway, assessments_xml_gateway: assessments_xml_gateway)
  end

  let(:statistics_gateway) { instance_double(Gateway::AssessmentStatisticsGateway) }
  let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }
  let(:assessments_xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }

  context "when deriving the statistics for a given date" do
    before do
      allow(statistics_gateway).to receive(:save)
      allow(assessments_gateway).to receive(:fetch_assessments_by_date).and_return(
        [
          { "assessment_id" => "0000-0000-0000-0000", "assessment_type" => "RdSAP", "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0001", "assessment_type" => "SAP", "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0002", "assessment_type" => "SAP", "scheme_id": 2 },
          { "assessment_id" => "0000-0000-0000-0003", "assessment_type" => "SAP", "scheme_id": 2 },
          { "assessment_id" => "0000-0000-0000-0004", "assessment_type" => "SAP", "scheme_id": 2 },
        ],
      )
      allow(assessments_xml_gateway).to receive(:fetch)
      allow(use_case).to receive(:stats_from_xml).with("0000-0000-0000-0000").and_return({ current_energy_rating: 58, transaction_type: "1" }) # rubocop:disable RSpec/SubjectStub
      allow(use_case).to receive(:stats_from_xml).with("0000-0000-0000-0001").and_return({ current_energy_rating: 50, transaction_type: "1" }) # rubocop:disable RSpec/SubjectStub
      allow(use_case).to receive(:stats_from_xml).with("0000-0000-0000-0002").and_return({ current_energy_rating: 30, transaction_type: "1" }) # rubocop:disable RSpec/SubjectStub
      allow(use_case).to receive(:stats_from_xml).with("0000-0000-0000-0003").and_return({ current_energy_rating: 50, transaction_type: "1" }) # rubocop:disable RSpec/SubjectStub
      allow(use_case).to receive(:stats_from_xml).with("0000-0000-0000-0004").and_return({ current_energy_rating: 89, transaction_type: "1" }) # rubocop:disable RSpec/SubjectStub
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
      # expect(assessments_xml_gateway).to have_received(:fetch).exactly(5).times
    end
  end
end
