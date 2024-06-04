describe Gateway::AssessmentsCountryIdGateway do
  let(:gateway) { described_class.new }

  describe "#insert" do
    let(:assessment_id) { "0000-0000-0001-1234-0000" }

    before do
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
  end
end
