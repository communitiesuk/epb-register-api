describe Gateway::AssessmentsCountryIdGateway do
  let(:gateway) { described_class.new }

  describe "#insert" do
    it "saves the row to the table" do
      assessment_id = "0000-0000-0001-1234-0000"
      country_id = 5
      expect { gateway.insert(assessment_id:, country_id:) }.not_to raise_error
      row = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_country_ids").first.symbolize_keys
      expectation = { assessment_id: "0000-0000-0001-1234-0000", country_id: 5 }
      expect(row).to eq expectation
    end
  end
end
