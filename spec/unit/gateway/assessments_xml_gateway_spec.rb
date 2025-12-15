describe Gateway::AssessmentsXmlGateway do
  include RSpecRegisterApiServiceMixin
  context "when interacting with the assessments xml tables" do
    subject(:gateway) { described_class.new }

    let(:record) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        xml: "<RRN>0000-0000-0000-0000-0000</RRN>",
        schema_type: "RdSAP-Schema-19.0.0",
      }
    end

    let(:scottish_record) do
      {
        assessment_id: "0000-0000-0000-0000-0001",
        xml: "<RRN>0000-0000-0000-0000-0001</RRN>",
        schema_type: "RdSAP-Schema-S-19.0",
      }
    end

    let(:ni_record) do
      {
        assessment_id: "0000-0000-0000-0000-0002",
        xml: "<RRN>0000-0000-0000-0000-0002</RRN>",
        schema_type: "CEPC-NI-8.0.0",
      }
    end

    before do
      Gateway::SchemesGateway::Scheme.create(scheme_id: "1")
      Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id: "12", first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: "1")
    end

    describe "#sent_to_db" do
      it "sends the xml record to the assessments xml table" do
        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0000", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
        expect(gateway.send_to_db(record, false).assessment_id).to eq("0000-0000-0000-0000-0000")
      end

      it "sends the xml record to the assessments xml table" do
        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id: "12", type_of_assessment: "CEPC", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
        expect(gateway.send_to_db(ni_record, false).assessment_id).to eq("0000-0000-0000-0000-0002")
      end

      it "sends the Scottish xml record to the Scottish assessments xml table" do
        Gateway::AssessmentsGateway::AssessmentScotland.create(assessment_id: "0000-0000-0000-0000-0001", scheme_assessor_id: "12", type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)
        gateway.send_to_db(scottish_record, true)
        result = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments_xml WHERE assessment_id = '0000-0000-0000-0000-0001'",
        ).entries.first

        expect(result["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      end
    end
  end
end
