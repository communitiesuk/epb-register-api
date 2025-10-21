describe Gateway::AssessmentsAddressIdGateway do
  let(:gateway) { described_class.new }

  before(:all) do
    Gateway::SchemesGateway::Scheme.create(scheme_id: "999")
    Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id: "TEST123456", first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: "999")
    Gateway::AssessmentsGateway::Assessment.insert_all([
      { assessment_id: "0000-0000-0000-0000-0001", scheme_assessor_id: "TEST123456", type_of_assessment: "CEPC", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50 },
      { assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id: "TEST123456", type_of_assessment: "CEPC", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50 },
      { assessment_id: "0000-0000-0000-0000-0003", scheme_assessor_id: "TEST123456", type_of_assessment: "CEPC", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50 },
    ])
    Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.insert_all([
      { assessment_id: "0000-0000-0000-0000-0001", address_id: "RRN-0000-0000-0000-0000-0001", source: "lodgement" },
      { assessment_id: "0000-0000-0000-0000-0002", address_id: "RRN-0000-0000-0000-0000-0001", source: "lodgement" },
      { assessment_id: "0000-0000-0000-0000-0003", address_id: "RRN-0000-0000-0000-0000-0002", source: "lodgement" },
    ])
    Timecop.freeze(2024, 12, 22, 0, 0, 0)
  end

  after(:all) do
    Timecop.return
  end

  describe "#update_assessments_address_id_mapping" do
    context "when there is not source argument" do
      it "updates assessments to with a new address_id", :aggregate_failures do
        assessment_ids = %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
        gateway.update_assessments_address_id_mapping(assessment_ids, "UPRN-000000000001")
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0001").pluck(:address_id)).to eq %w[UPRN-000000000001]
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0003").pluck(:address_id)).to eq %w[RRN-0000-0000-0000-0000-0002]
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0001").pluck(:source)).to eq %w[epb_team_update]
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0003").pluck(:source)).to eq %w[lodgement]
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0001").pluck(:address_updated_at)).to eq [Time.parse("2024-12-22 00:00:00.000000000 +0000")]
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0003").pluck(:address_updated_at)).to eq [nil]
      end
    end

    context "when a source argument is passed through" do
      it "updates assessments with a new address_id source", :aggregate_failures do
        assessment_ids = %w[0000-0000-0000-0000-0002]
        gateway.update_assessments_address_id_mapping(assessment_ids, "UPRN-000000000002", "epb_bulk_linking")
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0002").pluck(:address_id)).to eq %w[UPRN-000000000002]
        expect(Gateway::AssessmentsAddressIdGateway::AssessmentsAddressId.where(assessment_id: "0000-0000-0000-0000-0002").pluck(:source)).to eq %w[epb_bulk_linking]
      end
    end
  end

  describe "#fetch" do
    context "when fetching an assessment id" do
      it "returns the expected response" do
        expected_response = {
          address_id: "RRN-0000-0000-0000-0000-0001",
          address_updated_at: nil,
          assessment_id: "0000-0000-0000-0000-0001",
          source: "lodgement",
        }
        assessment_id = "0000-0000-0000-0000-0001"
        response = gateway.fetch(assessment_id)

        expect(response).to eq expected_response
      end

      it "returns the expected response for a Scottish assessment" do
        ActiveRecord::Base.connection.exec_query(
          "INSERT INTO scotland.assessments_address_id(assessment_id, address_id, source, address_updated_at) VALUES('0000-0000-0000-0000-0002', 'RRN-0000-0000-0000-0000-0002', 'lodgement', null)",
        )

        expected_response = {
          address_id: "RRN-0000-0000-0000-0000-0002",
          address_updated_at: nil,
          assessment_id: "0000-0000-0000-0000-0002",
          source: "lodgement",
        }
        assessment_id = "0000-0000-0000-0000-0002"
        response = gateway.fetch(assessment_id, is_scottish: true)

        expect(response).to eq expected_response
      end
    end
  end

  describe "#send_to_db" do
    context "when creating an assessment" do
      it "returns the expected response" do
        entry = {
          assessment_id: "0000-0000-0000-0000-0001",
          address_id: "RRN-0000-0000-0000-0000-0001",
          source: "lodgement",

        }
        gateway.send_to_db(entry)
        row = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM assessments_address_id WHERE assessment_id = '0000-0000-0000-0000-0001'",
        )

        expect(row.entries.first["assessment_id"]).to eq "0000-0000-0000-0000-0001"
      end

      it "returns the expected response for a Scottish entry" do
        entry = {
          assessment_id: "0000-0000-0000-0000-0001",
          address_id: "RRN-0000-0000-0000-0000-0001",
          source: "lodgement",

        }
        gateway.send_to_db(entry, is_scottish: true)
        row = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments_address_id WHERE assessment_id = '0000-0000-0000-0000-0001'",
        )

        expect(row.entries.first["assessment_id"]).to eq "0000-0000-0000-0000-0001"
      end
    end
  end

  describe "#fetch_updated_group_count" do
    context "when fetching updated group count" do
      it "returns the number of updated address groups" do
        assessment_ids = %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
        gateway.update_assessments_address_id_mapping(assessment_ids, "UPRN-000000000001", "epb_bulk_linking")
        number_of_groups = gateway.fetch_updated_group_count(Time.now)
        expect(number_of_groups).to eq 1
      end
    end
  end

  describe "#fetch_updated_address_id_count" do
    context "when fetching updated address id count" do
      it "returns the number of updated address ids" do
        assessment_ids = %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002]
        gateway.update_assessments_address_id_mapping(assessment_ids, "UPRN-000000000001", "epb_bulk_linking")
        number_of_address_ids = gateway.fetch_updated_address_id_count(Time.now)
        expect(number_of_address_ids).to eq 2
      end
    end
  end
end
