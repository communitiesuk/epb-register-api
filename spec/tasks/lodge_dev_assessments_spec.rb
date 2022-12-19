shared_context "when lodging dev data" do
  def table_data(table:)
    ActiveRecord::Base.connection.exec_query("SELECT * FROM #{table} ORDER BY assessment_id")
  end
end

describe "lodge_dev_assessments rake" do
  include RSpecRegisterApiServiceMixin
  include_context "when lodging dev data"

  context "when calling the rake task in production" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("STAGE").and_return("production")
    end

    it "raises an error and does not add anything to the database" do
      expect { get_task("dev_data:lodge_dev_assessments").invoke }.to raise_error(
        StandardError,
      ).with_message("This task can only be run if the STAGE is test, development, integration or staging")
    end
  end

  context "when calling the rake task in test (not production)" do
    before(:all) do
      Timecop.freeze(2022, 12, 12, 7, 0, 0)
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes(scheme_id,name,active) VALUES (1, 'emck', true)")
      insert_sql = "INSERT INTO assessors(scheme_assessor_id, first_name,last_name,date_of_birth,registered_by,telephone_number,email,domestic_rd_sap_qualification,non_domestic_sp3_qualification,non_domestic_cc4_qualification,
      non_domestic_dec_qualification,non_domestic_nos3_qualification,non_domestic_nos5_qualification,non_domestic_nos4_qualification,domestic_sap_qualification,gda_qualification)
                  VALUES ('RAKE000001', 'test_forename', 'test_surname', '1970-01-05', '1', '0202207459', 'test@barr.com', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE','ACTIVE','ACTIVE','ACTIVE','ACTIVE')"
      ActiveRecord::Base.connection.exec_query(insert_sql)
      get_task("dev_data:lodge_dev_assessments").invoke
    end

    after(:all) do
      Timecop.return
    end

    let!(:exported_data) { table_data(table: "assessments") }
    let!(:exported_assessments_address_id) { table_data(table: "assessments_address_id") }
    let!(:exported_linked_assessments) { table_data(table: "linked_assessments") }

    it "lodges seed data into the database", aggregate_failures: true do
      expect(exported_data.rows.length).to eq(63)
      expect(exported_data.count { |row| row["type_of_assessment"] == "CEPC-RR" }).to eq(6)
      expect(exported_data.count { |row| row["type_of_assessment"] == "CEPC" }).to eq(6)
      expect(exported_data.count { |row| row["type_of_assessment"] == "DEC-RR" }).to eq(6)
      expect(exported_data.count { |row| row["type_of_assessment"] == "DEC" }).to eq(6)
      expect(exported_data.count { |row| row["type_of_assessment"] == "AC-CERT" }).to eq(6)
      expect(exported_data.count { |row| row["type_of_assessment"] == "AC-REPORT" }).to eq(6)
      expect(exported_data.count { |row| row["type_of_assessment"] == "SAP" }).to eq(12)
      expect(exported_data.count { |row| row["type_of_assessment"] == "RdSAP" }).to eq(15)
    end

    it "lodges data from updated xml into the assessments table", aggregate_failures: true do
      first_result = exported_data.first
      expect(first_result["type_of_assessment"]).to eq("RdSAP")
      expect(first_result["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      expect(first_result["scheme_assessor_id"]).to eq("RAKE000001")
      expect(first_result["address_line1"]).to eq("1a Some Street")
      expect(first_result["date_of_assessment"]).to eq("2017-12-12")
      expect(first_result["date_registered"]).to eq("2017-12-12")
      expect(first_result["date_of_expiry"]).to eq("2027-12-11")
      expect(first_result["address_id"]).to eq("RRN-0000-0000-0000-0000-0001")
    end

    it "lodges a dec with the correct expiry date" do
      dec = exported_data.find { |row| row["type_of_assessment"] == "DEC" }
      expect(dec["date_of_expiry"]).to eq("2027-12-11")
    end

    it "lodges a dec-rr with a BT postcode with the correct expiry date" do
      dec_rr_ni = exported_data.find { |row| row["type_of_assessment"] == "DEC-RR" && row["postcode"].start_with?("BT") }
      expect(dec_rr_ni["date_of_expiry"]).to eq("2024-12-11")
    end

    context "when lodging superseded, valid and expired certificates" do
      let(:superseded_cert) { exported_data.first }
      let(:valid_cert) { exported_data[1] }
      let(:superseded_address_id) { exported_assessments_address_id.first }
      let(:valid_address_id) { exported_assessments_address_id[1] }

      it "creates a superseded and valid pair that are linked" do
        expect(superseded_cert["type_of_assessment"]).to eq("RdSAP")
        expect(valid_cert["type_of_assessment"]).to eq("RdSAP")
        expect(superseded_cert["address_id"]).to eq valid_cert["address_id"]
      end

      it "creates a superseded and valid pair with different expiry dates " do
        expect(superseded_cert["date_of_expiry"]).to be < valid_cert["date_of_expiry"]
      end

      it "links the address ids in the assessments_address_id table" do
        expect(superseded_address_id["address_id"]).to eq(valid_address_id["address_id"])
      end
    end

    context "when lodging superseded and valid pairs for SAP-Schema-16.3, SAP-Schema-13.0, SAP-Schema-10.2" do
      let(:superseded_cert) { exported_data.find { |row| row["assessment_id"] == "0000-0000-0000-0000-0013" } }
      let(:valid_cert) { exported_data.find { |row| row["assessment_id"] == "0000-0000-0000-0000-0014" } }
      let(:superseded_cert_address) { exported_assessments_address_id.find { |row| row["assessment_id"] == "0000-0000-0000-0000-0013" } }

      it "updates the same address id to the same value" do
        expect(superseded_cert["address_id"]).to eq(superseded_cert_address["address_id"])
        expect(valid_cert["address_id"]).to eq(superseded_cert_address["address_id"])
      end
    end

    context "when creating an expired certificate" do
      let(:expired_result) { exported_data[2] }

      it "sets the date of expiry to before now" do
        expect(expired_result["date_of_expiry"]).to be < Time.now
      end
    end

    context "when lodging dual assessments" do
      let(:dec) { exported_data.find { |row| row["type_of_assessment"] == "DEC" } }
      let(:dec_rr) { exported_data.find { |row| row["type_of_assessment"] == "DEC-RR" } }
      let(:dec_linked_data) { exported_linked_assessments.find { |row| row["assessment_id"] == "0000-0000-0000-0000-0052" } }

      it "lodges the DEC cert with the report and links them together" do
        expect(dec["assessment_id"]).to eq("0000-0000-0000-0000-0052")
        expect(dec_rr["assessment_id"]).to eq("0000-0000-0000-0000-0053")
        expect(dec_linked_data["linked_assessment_id"]).to eq(dec_rr["assessment_id"])
      end
    end

    it "loads the xml from the factory" do
      expect { UseCase::AssessmentSummary::Fetch.new.execute("0000-0000-0000-0000-0001") }.not_to raise_error
    end
  end
end
