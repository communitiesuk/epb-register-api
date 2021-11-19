describe Gateway::AssessmentStatisticsGateway do
  subject(:gateway) { described_class.new }

  describe "#save" do
    let(:saved_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics ORDER BY assessment_type")
    end

    it "save the expected data to the database" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2, country: "England & Wales")
      gateway.save(assessment_type: "SAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 1, country: "Northern Ireland")

      expect(saved_data.first.symbolize_keys).to match a_hash_including({ assessment_type: "RdSAP", assessments_count: 56, rating_average: 29.0, day_date: Time.now.to_date, transaction_type: 2, country: "England & Wales" })
      expect(saved_data.last.symbolize_keys).to match a_hash_including({ assessment_type: "SAP", assessments_count: 79, rating_average: 28.0, day_date: Time.now.to_date, transaction_type: 1, country: "Northern Ireland" })
    end

    it "can save nil values for rating_average and transaction_type" do
      expect { gateway.save(assessment_type: "AC-Report", assessments_count: 20, rating_average: nil, day_date: Time.now.to_date, transaction_type: nil) }.not_to raise_error
    end

    it "raises and key constraint error if the same data is saved more then once" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2)
      expect { gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 2) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#min_assessment_date" do
    it "returns the date yesterday if there is no stat date present" do
      expect(gateway.min_assessment_date).to eq(Time.now.to_date - 1)
    end

    it "returns the earliest data we have stats data for" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Date.parse("01-09-2021"), transaction_type: 1)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Date.parse("02-08-2021"), transaction_type: 1)
      expect(gateway.min_assessment_date.strftime("%F")).to eq("2021-08-02")
    end
  end

  describe "#fetch_monthly_stats" do
    before do
      england = "England & Wales"
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date:  Date.parse("04-07-2021"), transaction_type: 1, country: england)
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date:  Date.parse("04-09-2021"), transaction_type: 2, country: england)
      gateway.save(assessment_type: "SAP", assessments_count: 56, rating_average: 29, day_date:  Date.parse("03-09-2021"), transaction_type: 2, country: england)
      gateway.save(assessment_type: "RdSAP", assessments_count: 2, rating_average: 60, day_date:  Date.parse("30-09-2021"), transaction_type: 1, country: england)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 61, day_date: Date.parse("01-09-2021"), transaction_type: 1, country: england)
      gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Date.parse("02-08-2021"), transaction_type: 4, country: england)
    end

    let(:expected_results) do
      [
        { "num_assessments" => 82, "rating_average" => 78.0, "month" => "2021-07", "assessment_type" => "SAP" },
        { "num_assessments" => 24, "rating_average" => 28.0, "month" => "2021-08", "assessment_type" => "RdSAP"  },
        { "num_assessments" => 81, "rating_average" => 60.5, "month" => "2021-09", "assessment_type" => "RdSAP"  },
        { "num_assessments" => 138, "rating_average" => 53.5, "month" => "2021-09", "assessment_type" => "SAP" },

      ]
    end

    it "returns the expected aggregate data for last month" do
      results = gateway.fetch_monthly_stats.sort_by { |h| [h["month"], h["assessment_type"]] }
      expect(results).to eq expected_results
    end

    it "does not return the additional row - data saved in the current month" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Time.now, transaction_type: 4)
      expect(gateway.fetch_monthly_stats.length).to eq(4)
    end
  end

  describe "#fetch_monthly_stats_by_country" do
    before do
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date: Date.parse("04-07-2021"), transaction_type: 1, country: "England & Wales")
      gateway.save(assessment_type: "RdSAP", assessments_count: 93, rating_average: 62, day_date: Date.parse("04-09-2021"), transaction_type: 2, country: "England & Wales")
      gateway.save(assessment_type: "SAP", assessments_count: 10, rating_average: 42, day_date: Date.parse("04-09-2021"), transaction_type: 2, country: "Northern Ireland")
      gateway.save(assessment_type: "RdSAP", assessments_count: 5, rating_average: 50, day_date: Date.parse("04-09-2021"), transaction_type: 2, country: "Northern Ireland")
    end

    let(:expected_results) do
      [{ "num_assessments" => 82, "rating_average" => 78.0, "month" => "2021-07", "assessment_type" => "SAP", "country" => "England & Wales" },
       { "num_assessments" => 93, "rating_average" => 62.0, "month" => "2021-09", "assessment_type" => "RdSAP",  "country" => "England & Wales" },
       { "num_assessments" => 5, "rating_average" => 50.0, "month" => "2021-09", "assessment_type" => "RdSAP",   "country" => "Northern Ireland" },
       { "num_assessments" => 10, "rating_average" => 42.0, "month" => "2021-09", "assessment_type" => "SAP", "country" => "Northern Ireland" }]
    end

    it "returns the expected aggregate data by country" do
      results = gateway.fetch_monthly_stats_by_country.sort_by { |h| [h["country"], h["month"], h["assessment_type"]] }
      expect(results).to eq(expected_results)
    end
  end
end
