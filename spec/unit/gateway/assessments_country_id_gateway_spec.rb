describe Gateway::AssessmentsCountryIdGateway do
  let(:gateway) { described_class.new }
  let(:assessment_id) { "0000-0000-0001-1234-0000" }

  describe "#insert" do
    before do
      add_countries
      gateway.insert(assessment_id:, country_id: 5)
    end

    it "saves the row to the table" do
      row = described_class::AssessmentsCountryId.find_by(assessment_id:)
      expect(row.assessment_id).to eq assessment_id
      expect(row.country_id).to eq 5
    end

    context "when inserting an existing assessment_id" do
      it "updates the row without error using upsert" do
        gateway.insert(assessment_id:, country_id: 1, upsert: true)
        row = described_class::AssessmentsCountryId.find_by(assessment_id:)
        expect(row.country_id).to eq 1
      end

      it "raises an AssessmentAlreadyExists error" do
        expect { gateway.insert(assessment_id:, country_id: 1) }.to raise_error Gateway::AssessmentsGateway::AssessmentAlreadyExists
      end
    end

    context "when inserting an assessment into the scotland equivalent of the assessments_country_ids table" do
      it "it saves the row to the table" do
        assessment_id = "0000-0000-0001-1234-0022"
        gateway.insert(assessment_id:, country_id: 2, upsert: true, is_scottish: true)
        row = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments_country_ids WHERE assessment_id = '0000-0000-0001-1234-0022'",
        )
        expect(row.entries.first["country_id"]).to eq 2
      end
    end
  end

  describe "fetch_country_name" do
    before do
      add_countries
      gateway.insert(assessment_id:, country_id: 1)
    end

    it "gets the country name" do
      response = gateway.fetch_country_name("0000-0000-0001-1234-0000")
      expect(response["country_name"]).to eq "England"
    end
  end
end
