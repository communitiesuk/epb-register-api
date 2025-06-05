describe UseCase::FetchMonthlyAssessmentStats do
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

  context "when extracting month assessments report" do
    before do
      allow(stats_gateway).to receive(:fetch_monthly_stats_by_country).and_return(country_data)
    end

    let(:country_data) do
      [{ "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP", "country" => "Northern Ireland" },
       { "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP", "country" => "Other" },
       { "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP", "country" => "England" },
       { "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP", "country" => "Wales" }]
    end

    it "executes the use case and returns a hash of the the combines data set" do
      country_data.each { |i| data << i }
      expect((use_case.execute[:all] - data) | (data - use_case.execute[:all])).to be_empty
    end

    it "executes the use case and returns a hash of the the NI data" do
      expect(use_case.execute[:northern_ireland]).to eq([country_data.first])
    end

    it "executes the use case and returns a hash of the the Other data" do
      expect(use_case.execute[:other]).to eq([country_data.find { |stats| stats["country"] == "Other" }])
    end

    it "executes the use case and returns a hash of the the Wales data" do
      expect(use_case.execute[:wales]).to eq([country_data.find { |stats| stats["country"] == "Wales" }])
    end

    it "executes the use case and returns a hash of the the England & Wales data" do
      expect(use_case.execute[:england]).to eq([country_data.find { |stats| stats["country"] == "England" }])
    end
  end
end
