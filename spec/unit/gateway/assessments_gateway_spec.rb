shared_context "when updating EPC dates" do
  def fetch_created_at(assessment_id)
    Gateway::AssessmentsGateway::Assessment.find_by(assessment_id:).created_at
  end
end

describe Gateway::AssessmentsGateway do
  subject(:gateway) { described_class.new }

  let(:scheme_assessor_id) do
    "TEST123456"
  end
  let(:scheme_id) do
    "9999"
  end

  include RSpecRegisterApiServiceMixin
  include_context "when updating EPC dates"

  describe "#fetch_assessments_by_date" do
    before do
      Gateway::SchemesGateway::Scheme.create(scheme_id:)
      Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id:, first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: scheme_id)

      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0000", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 50)

      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0001", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry:  "2070-01-02", current_energy_efficiency_rating: 50)
    end

    it "returns the assessment data for a given day" do
      expect(gateway.fetch_assessments_by_date(date: "2010-01-05")).to match([
        a_hash_including(
          { "assessment_id" => "0000-0000-0000-0000-0000",
            "type_of_assessment" => "SAP",
            "scheme_id" => 9999,
            "current_energy_efficiency_rating" => 50,
            "country" => "England & Wales" },
        ),
      ])
    end

    it "raises an error when an invalid type is provided" do
      expect { gateway.fetch_assessments_by_date(date: "2010-01-05", assessment_types: %w[Non-Existing]) }.to raise_error(StandardError, "Invalid types")
    end

    it "allows to filter by assessment type" do
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry: "2070-01-02", current_energy_efficiency_rating: 50)

      expect(gateway.fetch_assessments_by_date(date: "2010-01-05", assessment_types: %w[SAP])).to match([
        a_hash_including(
          { "assessment_id" => "0000-0000-0000-0000-0000",
            "type_of_assessment" => "SAP",
            "scheme_id" => 9999 },
        ),
      ])
    end

    it "returns data whose country is Northern Ireland" do
      today = Time.now.strftime("%Y-%m-%d")
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0005", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: today, date_registered: today, created_at: today, date_of_expiry: "2070-01-05", postcode: "BT4 3SR")

      expect(gateway.fetch_assessments_by_date(date: today).first).to eq({ "assessment_id" => "0000-0000-0000-0000-0005",
                                                                           "type_of_assessment" => "SAP",
                                                                           "current_energy_efficiency_rating" => 1,
                                                                           "scheme_id" => 9999,
                                                                           "country" => "Northern Ireland" })
    end
  end

  describe "#fetch_assessment_id_by_date_and_type" do
    before do
      add_countries
      Gateway::SchemesGateway::Scheme.create(scheme_id:)
      Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id:, first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: scheme_id)

      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0000", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2024-01-31", date_registered: "2024-01-31", created_at: "2024-01-31", date_of_expiry:  "2034-01-31", current_energy_efficiency_rating: 50)

      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0001", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2024-02-01", date_registered: "2024-02-01", created_at: "2024-02-01", date_of_expiry:  "2034-02-01", current_energy_efficiency_rating: 50)

      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2024-01-05", date_registered: "2024-01-05", created_at: "2024-01-05", date_of_expiry:  "2034-01-05", current_energy_efficiency_rating: 50)

      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0004", scheme_assessor_id:, type_of_assessment: "CEPC", date_of_assessment: "2024-01-31", date_registered: "2024-01-31", created_at: "2024-01-31", date_of_expiry: "2034-01-05", current_energy_efficiency_rating: 50)

      Gateway::AssessmentsCountryIdGateway.new.insert(assessment_id: "0000-0000-0000-0000-0002", country_id: 1)
    end

    it "returns expected list of assessment_ids between two dates" do
      expect(gateway.fetch_assessment_id_by_date_and_type(date_from: "2024-01-01", date_to: "2024-01-31")).to include("0000-0000-0000-0000-0000", "0000-0000-0000-0000-0004")
    end

    context "when the schema type is passed" do
      it "returns expected only of assessment_ids between two dates of a certain schema_type" do
        expect(gateway.fetch_assessment_id_by_date_and_type(date_from: "2024-01-01", date_to: "2024-01-31", assessment_types: %w[SAP])).to eq %w[0000-0000-0000-0000-0000]
      end

      it "returns an error when an incorrect schema is passed" do
        expect { gateway.fetch_assessment_id_by_date_and_type(date_from: "2024-01-01", date_to: "2024-01-31", assessment_types: %w[SAP CEEEPC]) }.to raise_error(StandardError, "Invalid types")
      end
    end
  end

  describe "#fetch_location_by_assessment_id" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)
      xml = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      lodge_assessment(
        assessment_body: xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    it "returns the postcode and address_id", :aggregate_failures do
      result = gateway.fetch_location_by_assessment_id("0000-0000-0000-0000-0000")
      expect(result["assessment_id"]).to eq "0000-0000-0000-0000-0000"
      expect(result["postcode"]).to eq "SW1A 2AA"
      expect(result["address_id"]).to eq "UPRN-000000000000"
      expect(Nokogiri.XML(result["xml"])).to be_a Nokogiri::XML::Document
      expect(result["schema_type"]).to eq "RdSAP-Schema-20.0.0"
    end
  end

  describe "#insert" do
    context "when inserting an assessment with data that already exists on the database" do
      before do
        Gateway::SchemesGateway::Scheme.create(scheme_id: "TEST123456")
        Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id:, first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: "TEST123456")

        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2024-01-04", date_registered: "2024-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50)

        allow(Gateway::AssessmentsGateway::Assessment).to receive(:exists?).and_return(false)
      end

      it "raises an assessment already exists exception" do
        assessment = Domain::AssessmentIndexRecord.new(
          assessment_id: "0000-0000-0000-0000-0002",
          type_of_assessment: "RdSAP",
          date_of_assessment: "2010-01-04",
          date_registered: "2010-01-05",
          date_of_expiry: "2010-01-05",
          assessor: Domain::Assessor.new(scheme_assessor_id: "TEST123456"),
          current_energy_efficiency_rating: 60,
          potential_energy_efficiency_rating: 75,
        )
        expect { gateway.insert assessment }.to raise_error described_class::AssessmentAlreadyExists
      end
    end

    context "when lodging a scottish assessment before adding the scottish schema to the database" do
      before do
        Gateway::SchemesGateway::Scheme.create(scheme_id: "TEST123456")
        Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id:, first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: "TEST123456")
        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2024-01-04", date_registered: "2024-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50)
      end

      it "raises an active record statement invalid error" do
        assessment = Domain::AssessmentIndexRecord.new(
          assessment_id: "0000-0000-0000-0000-0002",
          type_of_assessment: "RdSAP",
          date_of_assessment: "2010-01-04",
          date_registered: "2010-01-05",
          date_of_expiry: "2010-01-05",
          assessor: Domain::Assessor.new(scheme_assessor_id: "TEST123456"),
          current_energy_efficiency_rating: 60,
          potential_energy_efficiency_rating: 75,
          )
        expect { gateway.insert(assessment, is_scottish: true) }.to raise_error(ActiveRecord::StatementInvalid, /schema "scotland" does not exist/)
      end
    end
  end

  describe "#update_field" do
    let(:scheme_id) { add_scheme_and_get_id }

    before do
      add_super_assessor(scheme_id:)
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end

    it "updates the fields with the expected value" do
      gateway.update_field("0000-0000-0000-0000-0000", "type_of_assessment", "SAP")
      result = Gateway::AssessmentsGateway::Assessment.find_by(assessment_id: "0000-0000-0000-0000-0000")
      expect(result.type_of_assessment).to eq("SAP")
    end

    it "updates the created_at with a correct date" do
      gateway.update_field("0000-0000-0000-0000-0000", "created_at", "2024-01-16 17:52:43.00000")
      result = Gateway::AssessmentsGateway::Assessment.find_by(assessment_id: "0000-0000-0000-0000-0000")
      expect(result.created_at).to eq("2024-01-16 17:52:43.00000")
    end

    it "does not raise an error when no ID is found" do
      expect { gateway.update_field("0000-0000-0000-0000-0004", "created_at", "2024-01-16 17:52:43.00000") }.not_to raise_error
    end
  end

  describe "#update_created_at_from_landmark" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:landmark_date) do
      "2019-01-16 17:52:43.00000"
    end

    before do
      Timecop.freeze(2020, 6, 22, 0, 0, 0)

      add_super_assessor(scheme_id:)
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )

      domestic_rdsap_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end

    after do
      Timecop.return
    end

    it "returns true when the row is updated" do
      result = gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0000", landmark_date)
      expect(result).to be true
    end

    it "updates only the row with specified RRN", :aggregate_failure do
      gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0000", landmark_date)
      expect(fetch_created_at("0000-0000-0000-0000-0000")).to eq(landmark_date)
      expect(fetch_created_at("0000-0000-0000-0000-0001")).not_to eq(landmark_date)
    end

    it "does not raise an error when no assessment_id is found" do
      expect { gateway.update_created_at_from_landmark?("blah", landmark_date) }.not_to raise_error
    end

    it "returns false if the date is not in range", :aggregate_failure do
      expect(gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0001", "2024-01-16 17:52:43.00000")).to be false
      expect(gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0001", "1900-01-16 17:52:43.00000")).to be false
    end

    it "returns false when the assessment_id is for an EPC that has NOT been migrated" do
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET migrated = false WHERE assessment_id = '0000-0000-0000-0000-0001'")
      expect(gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0001", landmark_date)).to be false
    end
  end
end
