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
end
