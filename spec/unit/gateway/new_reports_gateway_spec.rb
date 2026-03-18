describe Gateway::NewReportsGateway do
  context "when fetching a list of rrns" do
    subject(:gateway) { described_class.new }

    before do
      Gateway::SchemesGateway::Scheme.create(scheme_id: "1")
      Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id: "12", first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: "1")

      Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0001", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-06", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
      Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-05", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
      Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0003", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-04", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
      Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0004", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-03", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
      Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0005", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
      Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0006", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-01", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
    end

    describe "#fetch" do
      describe "when there are more results than the limit" do
        describe "when you request the first page of results" do
          it "returns a result set the size of the limit" do
            results = gateway.fetch(start_date: "2010-01-02", end_date: "2010-01-06", current_page: 1, limit: 3)
            expect(results.length).to eq(3)
            expect(results).to eq(%w[0000-0000-0000-0000-0005 0000-0000-0000-0000-0004 0000-0000-0000-0000-0003])
          end
        end

        describe "when you request the last page of results" do
          it "returns the remaining results" do
            results = gateway.fetch(start_date: "2010-01-02", end_date: "2010-01-06", current_page: 2, limit: 3)
            expect(results.length).to eq(1)
            expect(results).to eq(%w[0000-0000-0000-0000-0002])
          end
        end
      end

      describe "when there are fewer results than the limit" do
        describe "when you request the first page of results" do
          it "returns a result set smaller than the limit" do
            results = gateway.fetch(start_date: "2010-01-04", end_date: "2010-01-06", current_page: 1, limit: 3)
            expect(results.length).to eq(2)
            expect(results).to eq(%w[0000-0000-0000-0000-0003 0000-0000-0000-0000-0002])
          end
        end

        describe "when you request a second page of results" do
          it "returns no results" do
            results = gateway.fetch(start_date: "2010-01-04", end_date: "2010-01-06", current_page: 2, limit: 3)
            expect(results.length).to eq(0)
          end
        end
      end
    end

    describe "#count" do
      it "returns a count of the number of results between two dates" do
        result = gateway.count(start_date: "2010-01-02", end_date: "2010-01-06")
        expect(result).to eq(4)
      end
    end
  end
end
