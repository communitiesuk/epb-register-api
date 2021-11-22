describe UseCase::FetchMonthlyAssessmentStats do
  context "when extracting month assessments report " do
    subject(:use_case) { described_class.new(stats_gateway) }

    let(:stats_gateway)  do
      instance_double(Gateway::AssessmentStatisticsGateway)
    end

    let(:data) do
      [{ "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP" }]
    end

    let(:country_data) do
      [{ "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP", "country" => "Northern Ireland" },
       { "num_assessments" => 82, "rating_average" => 78.0, "month_year" => "07-2021", "assessment_type" => "SAP", "country" => "England & Wales" }]
    end

    before do
      allow(stats_gateway).to receive(:fetch_monthly_stats_by_country).and_return(country_data)
      allow(stats_gateway).to receive(:fetch_monthly_stats).and_return(data)
    end

    it "executes the use case and returns a hash of the the combines data set" do
      country_data.each { |i| data << i }
      expect(use_case.execute[:all]).to eq(data)
    end

    it "executes the use case and returns a hash of the the NI data" do
      expect(use_case.execute[:northern_ireland]).to eq([country_data.first])
    end

    it "executes the use case and returns a hash of the the England & Wales data" do
      expect(use_case.execute[:england_wales]).to eq([country_data.last])
    end
  end
end
