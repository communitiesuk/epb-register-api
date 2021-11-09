describe Gateway::AssessmentStatisticsGateway do
  subject(:gateway) { described_class.new }

  describe "#save" do
    let(:saved_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics ORDER BY assessment_type")
    end

    it "save the expected data to the database" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2)
      gateway.save(assessment_type: "SAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 1)

      expect(saved_data.first.symbolize_keys).to match a_hash_including({ assessment_type: "RdSAP", assessments_count: 56, rating_average: 29.0, day_date: Time.now.to_date, transaction_type: 2 })
      expect(saved_data.last.symbolize_keys).to match a_hash_including({ assessment_type: "SAP", assessments_count: 79, rating_average: 28.0, day_date: Time.now.to_date, transaction_type: 1 })
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
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date:  Date.parse("04-07-2021"), transaction_type: 1)
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date:  Date.parse("04-09-2021"), transaction_type: 2)
      gateway.save(assessment_type: "SAP", assessments_count: 56, rating_average: 29, day_date:  Date.parse("03-09-2021"), transaction_type: 2)
      gateway.save(assessment_type: "RdSAP", assessments_count: 2, rating_average: 60, day_date:  Date.parse("30-09-2021"), transaction_type: 1)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 61, day_date: Date.parse("01-09-2021"), transaction_type: 1)
      gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Date.parse("02-08-2021"), transaction_type: 4)
    end

    let(:expected_results){
      [{"num_assessments"=>82, "rating_average"=>78.0, "month_year"=>"07-2021",  "assessment_type" => "SAP", "transaction_type"=>1},
       {"num_assessments"=>24, "rating_average"=>28.0, "month_year"=>"08-2021",  "assessment_type" => "RdSAP", "transaction_type"=>4},
       {"num_assessments"=>138, "rating_average"=>53.5, "month_year"=>"09-2021",  "assessment_type" => "SAP",  "transaction_type"=>2},
       {"num_assessments"=>81, "rating_average"=>60.5, "month_year"=>"09-2021",  "assessment_type" => "RdSAP",  "transaction_type"=>1},
      ]
    }

    it "returns the expected aggregate data for last month" do
      results = gateway.fetch_monthly_stats.sort_by { | h | h["month_year"] }
      expect(results).to eq(expected_results)
    end
  end
end
