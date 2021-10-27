describe Gateway::AssessmentStatisticsGateway do
  subject(:gateway) { described_class.new }

  describe "#save" do
    let(:saved_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics ORDER BY assessment_type")
    end

    it "save the expected data to the database" do
      expect { gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2, scheme_id: 10) }.not_to raise_error
      expect { gateway.save(assessment_type: "SAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 1, scheme_id: 8) }.not_to raise_error
      expect(saved_data.first.symbolize_keys).to match a_hash_including({ id: 1, assessment_type: "RdSAP", assessments_count: 56, rating_average: 29.0, day_date: Time.now.to_date, transaction_type: 2, scheme_id: 10 })
      expect(saved_data.last.symbolize_keys).to match a_hash_including({ id: 2, assessment_type: "SAP", assessments_count: 79, rating_average: 28.0, day_date: Time.now.to_date, transaction_type: 1, scheme_id: 8 })
    end

    it "can save nil values for rating_average and transaction_type" do
      expect { gateway.save(assessment_type: "AC-Report", assessments_count: 20, rating_average: nil, day_date: Time.now.to_date, transaction_type: nil, scheme_id: 10) }.not_to raise_error
    end
  end
end
