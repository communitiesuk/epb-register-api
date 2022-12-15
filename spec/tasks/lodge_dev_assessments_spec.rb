describe "lodge_dev_assessments rake" do
  include RSpecRegisterApiServiceMixin
  before do
    Timecop.freeze(2022, 12, 12, 7, 0, 0)
  end

  context "when calling the rake task in production" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ENV["STAGE"] = "production"
    end

    after do
      ENV["STAGE"] = "test"
    end

    let!(:exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments") }

    it "raises an error and does not add anything to the database" do
      expect { get_task("dev_data:lodge_dev_assessments").invoke }.to raise_error(
        StandardError,
      ).with_message("This task can only be run if the STAGE is test, development, integration or staging")
      expect(exported_data.rows.length).to eq(0)
    end
  end

  context "when setting up the rake task in test (not production)" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes(scheme_id,name,active) VALUES (1, 'emck', true)")
      insert_sql = "INSERT INTO assessors(scheme_assessor_id, first_name,last_name,date_of_birth,registered_by,telephone_number,email,domestic_rd_sap_qualification,non_domestic_sp3_qualification,non_domestic_cc4_qualification,
      non_domestic_dec_qualification,non_domestic_nos3_qualification,non_domestic_nos5_qualification,non_domestic_nos4_qualification,domestic_sap_qualification,gda_qualification)
                  VALUES ('RAKE000001', 'test_forename', 'test_surname', '1970-01-05', '1', '0202207459', 'test@barr.com', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE','ACTIVE','ACTIVE','ACTIVE','ACTIVE')"
      ActiveRecord::Base.connection.exec_query(insert_sql)
    end

    let!(:assessors_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessors ORDER BY scheme_assessor_id") }
    let!(:schemes_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM schemes ORDER BY scheme_id") }

    it "lodges the assessors into the data base" do
      expect(schemes_data[0]["scheme_id"].to_s).to eq(assessors_data[0]["registered_by"].to_s)
      expect(assessors_data.rows.length).to eq 1
      expect(schemes_data.rows.length).to eq 1
    end
  end

  context "when calling the rake task in test (not production)" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes(scheme_id,name,active) VALUES (1, 'emck', true)")
      insert_sql = "INSERT INTO assessors(scheme_assessor_id, first_name,last_name,date_of_birth,registered_by,telephone_number,email,domestic_rd_sap_qualification,non_domestic_sp3_qualification,non_domestic_cc4_qualification,
      non_domestic_dec_qualification,non_domestic_nos3_qualification,non_domestic_nos5_qualification,non_domestic_nos4_qualification,domestic_sap_qualification,gda_qualification)
                  VALUES ('RAKE000001', 'test_forename', 'test_surname', '1970-01-05', '1', '0202207459', 'test@barr.com', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE','ACTIVE','ACTIVE','ACTIVE','ACTIVE')"
      ActiveRecord::Base.connection.exec_query(insert_sql)
      get_task("dev_data:lodge_dev_assessments").invoke
    end

    let!(:exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments ORDER BY assessment_id") }
    let!(:exported_xml) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_xml ORDER BY assessment_id") }
    let!(:exported_assessments_address_id) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_address_id ORDER BY assessment_id") }
    let!(:cepc_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'CEPC' ORDER BY assessment_id") }
    let!(:dec_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'DEC' ORDER BY assessment_id") }
    let!(:ac_cert_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'AC-CERT' ORDER BY assessment_id") }
    let!(:cepc_rr_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'CEPC-RR' ORDER BY assessment_id") }
    let!(:dec_rr_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'DEC-RR' ORDER BY assessment_id") }
    let!(:ac_report_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'AC-REPORT' ORDER BY assessment_id") }
    let!(:rdsap_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'RdSAP' ORDER BY assessment_id") }
    let!(:sap_exported_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE type_of_assessment = 'SAP' ORDER BY assessment_id") }
    let!(:linked_assessment_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM linked_assessments ORDER BY assessment_id") }
    let!(:address_id_data) { ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_address_id ORDER BY assessment_id") }

    it "lodges different types of seed data into the database", aggregate_failures: true do
      expect(exported_data.rows.length).to eq(63)
      expect(rdsap_exported_data.rows.length).to eq(15)
      expect(sap_exported_data.rows.length).to eq(12)
      expect(cepc_exported_data.rows.length).to eq(6)
      expect(dec_exported_data.rows.length).to eq(6)
      expect(ac_cert_exported_data.rows.length).to eq(6)
      expect(cepc_rr_exported_data.rows.length).to eq(6)
      expect(dec_rr_exported_data.rows.length).to eq(6)
      expect(ac_report_exported_data.rows.length).to eq(6)
    end

    it "lodges the seed data correctly" do
      first_result = exported_data.first
      expect(first_result["type_of_assessment"]).to eq("RdSAP")
      expect(first_result["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      expect(first_result["scheme_assessor_id"]).to eq("RAKE000001")
      expect(first_result["address_line1"]).to eq("1a Some Street")
      expect(first_result["town"]).to eq("Townplace")
      expect(first_result["postcode"]).to eq("SW1A 2AA")
      expect(first_result["current_energy_efficiency_rating"]).to eq(92)
      expect(first_result["date_of_assessment"]).to eq("2017-12-12")
      expect(first_result["date_registered"]).to eq("2017-12-12")
      expect(first_result["date_of_expiry"]).to eq("2027-12-11")
    end

    it "lodges an ac-cert with the correct dates" do
      ac_cert = ac_cert_exported_data.first
      expect(ac_cert["date_of_assessment"]).to eq("2017-12-12")
      expect(ac_cert["date_registered"]).to eq("2017-12-12")
      expect(ac_cert["date_of_expiry"]).to eq("2027-12-11")
    end

    it "lodges a dec with the correct dates" do
      dec = dec_exported_data.first
      expect(dec["date_of_assessment"]).to eq("2017-12-12")
      expect(dec["date_registered"]).to eq("2017-12-12")
      expect(dec["date_of_expiry"]).to eq("2027-12-11")
    end

    it "lodges a dec-rr with BT postcode with expiry date 7 years after issue date" do
      dec_rr_ni = dec_rr_exported_data[3]
      expect(dec_rr_ni["date_of_assessment"]).to eq("2017-12-12")
      expect(dec_rr_ni["date_registered"]).to eq("2017-12-12")
      expect(dec_rr_ni["date_of_expiry"]).to eq("2024-12-11")
    end

    context "when lodging superseded, valid and expired certificates" do
      let(:superseded_cert) { exported_data.first }
      let(:valid_cert) { exported_data[1] }
      let(:superseded_address_id) { exported_assessments_address_id.first }
      let(:valid_address_id) { exported_assessments_address_id[1] }
      let(:superseded_xml) { Nokogiri.XML exported_xml[0]["xml"] }
      let(:valid_xml) { Nokogiri.XML exported_xml[1]["xml"] }

      it "create a superseded and valid pair that are linked" do
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

      it "has the same address in the assessments table as in the xml" do
        expect(superseded_cert["address_id"]).to eq(valid_xml.at("UPRN").text)
        expect(valid_cert["address_id"]).to eq(valid_xml.at("UPRN").text)
      end
    end

    context "when lodging superseded and valid pairs for SAP-Schema-16.3, SAP-Schema-13.0, SAP-Schema-10.2" do
      let(:superseded_cert) { rdsap_exported_data[6] }
      let(:valid_cert) { rdsap_exported_data[7] }
      let(:superseded_cert_address) { address_id_data[12] }
      let(:valid_cert_address) { address_id_data[13] }

      it "has the same address id" do
        expect(superseded_cert["assessment_id"]).to eq("0000-0000-0000-0000-0013")
        expect(valid_cert["assessment_id"]).to eq("0000-0000-0000-0000-0014")
        expect(superseded_cert_address["assessment_id"]).to eq("0000-0000-0000-0000-0013")
        expect(valid_cert_address["assessment_id"]).to eq("0000-0000-0000-0000-0014")
        expect(superseded_cert["address_id"]).to eq(superseded_cert_address["address_id"])
        expect(valid_cert["address_id"]).to eq(superseded_cert_address["address_id"])
      end
    end

    context "when creating an expired certificate" do
      let(:parent_result) do
        exported_data[0]
      end
      let(:expired_result) do
        exported_data[2]
      end
      let(:parent_result_xml) do
        Nokogiri.XML exported_xml[0]["xml"]
      end
      let(:expired_result_xml) do
        Nokogiri.XML exported_xml[2]["xml"]
      end

      it "sets the date of expiry to before now" do
        expect(expired_result["date_of_expiry"]).to be < Time.now
      end

      it "sets the address in both the assessments and xml data to be different to its parent record" do
        expect(expired_result["address_line1"]).not_to eq(parent_result["address_line1"])
        expect(expired_result["address_id"]).not_to eq(parent_result["address_id"])
        expect(expired_result_xml.at("Address//Address-Line-1").text).not_to eq(parent_result_xml.at("Address//Address-Line-1").text)
      end
    end

    context "when lodging dual assessments" do
      let(:ac_cert) { ac_cert_exported_data[0] }
      let(:ac_report) { ac_report_exported_data[0] }

      let(:dec) { dec_exported_data[0] }
      let(:dec_rr) { dec_rr_exported_data[0] }

      let(:cepc_ni) { cepc_exported_data[3] }
      let(:cepc_ni_rr) { cepc_rr_exported_data[3] }

      it "lodges the AC-CERT with the Report" do
        expect(ac_cert["type_of_assessment"]).to eq("AC-CERT")
        expect(ac_cert["type_of_assessment"]).to eq("AC-CERT")
        expect(ac_report["type_of_assessment"]).to eq("AC-REPORT")
        expect(ac_cert["assessment_id"]).to eq("0000-0000-0000-0000-0028")
        expect(ac_report["assessment_id"]).to eq("0000-0000-0000-0000-0029")
        expect(linked_assessment_data[0]["assessment_id"]).to eq("0000-0000-0000-0000-0028")
        expect(linked_assessment_data[0]["linked_assessment_id"]).to eq("0000-0000-0000-0000-0029")
        expect(linked_assessment_data[1]["assessment_id"]).to eq("0000-0000-0000-0000-0029")
        expect(linked_assessment_data[1]["linked_assessment_id"]).to eq("0000-0000-0000-0000-0028")
      end

      it "lodges the DEC with the Report" do
        expect(dec["type_of_assessment"]).to eq("DEC")
        expect(dec_rr["type_of_assessment"]).to eq("DEC-RR")
        expect(dec["assessment_id"]).to eq("0000-0000-0000-0000-0052")
        expect(dec_rr["assessment_id"]).to eq("0000-0000-0000-0000-0053")
        expect(linked_assessment_data[24]["assessment_id"]).to eq("0000-0000-0000-0000-0052")
        expect(linked_assessment_data[24]["linked_assessment_id"]).to eq("0000-0000-0000-0000-0053")
        expect(linked_assessment_data[25]["assessment_id"]).to eq("0000-0000-0000-0000-0053")
        expect(linked_assessment_data[25]["linked_assessment_id"]).to eq("0000-0000-0000-0000-0052")
      end

      it "lodges NI CEPCs with the Report" do
        expect(cepc_ni["type_of_assessment"]).to eq("CEPC")
        expect(cepc_ni_rr["type_of_assessment"]).to eq("CEPC-RR")
        expect(cepc_ni["assessment_id"]).to eq("0000-0000-0000-0000-0046")
        expect(cepc_ni_rr["assessment_id"]).to eq("0000-0000-0000-0000-0047")
        expect(linked_assessment_data[18]["assessment_id"]).to eq("0000-0000-0000-0000-0046")
        expect(linked_assessment_data[18]["linked_assessment_id"]).to eq("0000-0000-0000-0000-0047")
        expect(linked_assessment_data[19]["assessment_id"]).to eq("0000-0000-0000-0000-0047")
        expect(linked_assessment_data[19]["linked_assessment_id"]).to eq("0000-0000-0000-0000-0046")
      end
    end

    it "loads the xml from the factory" do
      expect { UseCase::AssessmentSummary::Fetch.new.execute("0000-0000-0000-0000-0001") }.not_to raise_error
    end
  end
end
