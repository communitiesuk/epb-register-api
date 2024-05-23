shared_context "when updating EPC dates" do
  def fetch_created_at(assessment_id)
    ActiveRecord::Base.connection.exec_query("SELECT created_at FROM assessments WHERE assessment_id='#{assessment_id}'").first["created_at"]
  end
end

describe Gateway::AssessmentsGateway do
  subject(:gateway) { described_class.new }

  include RSpecRegisterApiServiceMixin
  include_context "when updating EPC dates"

  describe "#fetch_assessments_by_date" do
    before do
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('9999')")
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessors (scheme_assessor_id, first_name, last_name, date_of_birth, registered_by)
        VALUES ('TEST123456', 'test_forename', 'test_surname', '1970-01-05', 9999)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating)
        VALUES ('0000-0000-0000-0000-0000', 'TEST123456', 'SAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05', 50)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating)
        VALUES ('0000-0000-0000-0000-0001', 'TEST123456', 'SAP', '2010-01-01', '2010-01-01', '2010-01-02', '2070-01-02', 50)",
      )
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
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0002', 'TEST123456', 'RdSAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05')",
      )
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
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, postcode)
        VALUES ('0000-0000-0000-0000-0005', 'TEST123456', 'SAP', '#{today}', '#{today}', '#{today}', '2070-01-05', 'BT1 1AA')",
      )
      expect(gateway.fetch_assessments_by_date(date: today).first).to eq({ "assessment_id" => "0000-0000-0000-0000-0005",
                                                                           "type_of_assessment" => "SAP",
                                                                           "current_energy_efficiency_rating" => 1,
                                                                           "scheme_id" => 9999,
                                                                           "country" => "Northern Ireland" })
    end
  end

  describe "#fetch_assessment_id_by_date_and_type" do
    before do
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('9999')")
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessors (scheme_assessor_id, first_name, last_name, date_of_birth, registered_by)
        VALUES ('TEST123456', 'test_forename', 'test_surname', '1970-01-05', 9999)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating, country_id)
        VALUES ('0000-0000-0000-0000-0000', 'TEST123456', 'SAP', '2024-01-31', '2024-01-31', '2024-01-31', '2034-01-31', 50, NULL)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating, country_id)
        VALUES ('0000-0000-0000-0000-0001', 'TEST123456', 'SAP', '2024-02-01', '2024-02-01', '2024-02-01', '2034-02-01', 50, NULL)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating, country_id)
        VALUES ('0000-0000-0000-0000-0002', 'TEST123456', 'SAP', '2024-01-05', '2024-01-05', '2024-01-05', '2034-01-05', 50, NULL)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating, country_id)
        VALUES ('0000-0000-0000-0000-0004', 'TEST123456', 'CEPC', '2024-01-31', '2024-01-31', '2024-01-31', '2034-01-31', 50, NULL)",
      )
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
      expect(result["postcode"]).to eq "A0 0AA"
      expect(result["address_id"]).to eq "UPRN-000000000000"
      expect(Nokogiri.XML(result["xml"])).to be_a Nokogiri::XML::Document
      expect(result["schema_type"]).to eq "RdSAP-Schema-20.0.0"
    end
  end

  describe "#insert" do
    context "when inserting an assessment with data that already exists on the database" do
      before do
        ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('9999')")
        ActiveRecord::Base.connection.exec_query(
          "INSERT INTO assessors (scheme_assessor_id, first_name, last_name, date_of_birth, registered_by)
        VALUES ('TEST123456', 'test_forename', 'test_surname', '1970-01-05', 9999)",
        )
        ActiveRecord::Base.connection.exec_query(
          "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0002', 'TEST123456', 'RdSAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05')",
        )
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
      result = ActiveRecord::Base.connection.exec_query("SELECT type_of_assessment FROM assessments WHERE assessment_id='0000-0000-0000-0000-0000'").first["type_of_assessment"]
      expect(result).to eq("SAP")
    end

    it "updates the created_at with a correct date" do
      gateway.update_field("0000-0000-0000-0000-0000", "created_at", "2024-01-16 17:52:43.00000")
      result = ActiveRecord::Base.connection.exec_query("SELECT created_at FROM assessments WHERE assessment_id='0000-0000-0000-0000-0000'").first["created_at"]
      expect(result).to eq("2024-01-16 17:52:43.00000")
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

    it "updates only the row with specified RRN", aggregate_failure: true do
      gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0000", landmark_date)
      expect(fetch_created_at("0000-0000-0000-0000-0000")).to eq(landmark_date)
      expect(fetch_created_at("0000-0000-0000-0000-0001")).not_to eq(landmark_date)
    end

    it "does not raise an error when no assessment_id is found" do
      expect { gateway.update_created_at_from_landmark?("blah", landmark_date) }.not_to raise_error
    end

    it "returns false if the date is not in range", aggregate_failure: true do
      expect(gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0001", "2024-01-16 17:52:43.00000")).to be false
      expect(gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0001", "1900-01-16 17:52:43.00000")).to be false
    end

    it "returns false when the assessment_id is for an EPC that has NOT been migrated" do
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET migrated = false WHERE assessment_id = '0000-0000-0000-0000-0001'")
      expect(gateway.update_created_at_from_landmark?("0000-0000-0000-0000-0001", landmark_date)).to be false
    end
  end
end
