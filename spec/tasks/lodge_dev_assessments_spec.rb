describe "linked_dev_assessments rake" do
  include RSpecRegisterApiServiceMixin

  context "when calling the rake task in production" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ENV["STAGE"] = "production"
    end

    after do
      ENV["STAGE"] = "test"
    end

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments")
    end

    it "raises an error and does not add anything to the database" do
      expect { get_task("dev_data:lodge_dev_assessments").invoke }.to raise_error(
        StandardError,
      ).with_message("This task can only be run if the STAGE is test, development, integration or staging")
      expect(exported_data.rows.length).to eq(0)
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

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments ORDER BY assessment_id")
    end

    let!(:exported_xml) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_xml ORDER BY assessment_id")
    end

    let!(:exported_assessments_address_id) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments_address_id ORDER BY assessment_id")
    end

    it "loads the seed data into the database" do
      expect(exported_data.rows.length).to eq(51)
      first_result = exported_data.first
      expect(first_result["type_of_assessment"]).to eq("CEPC")
      expect(first_result["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      expect(first_result["scheme_assessor_id"]).to eq("RAKE000001")
      expect(first_result["address_line1"]).to eq("1 Some Unit")
      expect(first_result["address_line2"]).to eq("3 Unit Road")
      expect(first_result["address_line3"]).to eq("Some Area")
      expect(first_result["address_line4"]).to eq("Some County")
      expect(first_result["town"]).to eq("Townplace")
      expect(first_result["postcode"]).to eq("A0 0AA")
    end

    context "when creating a superseded and valid certificate pair" do
      let(:superseded_cert) do
        exported_data.first
      end
      let(:valid_cert) do
        exported_data[1]
      end
      let(:superseded_address_id) do
        exported_assessments_address_id.first
      end
      let(:valid_address_id) do
        exported_assessments_address_id[1]
      end

      it "provides linked certificates with different expiry dates" do
        expect(superseded_cert["type_of_assessment"]).to eq("CEPC")
        expect(valid_cert["type_of_assessment"]).to eq("CEPC")
        expect(superseded_cert["address_id"]).to eq valid_cert["address_id"]
        expect(superseded_cert["date_of_expiry"]).to be < valid_cert["date_of_expiry"]
      end

      it "links the address ids in the assessments_address_id table" do
        expect(superseded_address_id["address_id"]).to eq(valid_address_id["address_id"])
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
        expect(expired_result_xml.at("//CEPC:Property-Address//CEPC:Address-Line-1").text).not_to eq(parent_result_xml.at("//CEPC:Property-Address//CEPC:Address-Line-1").text)
        expect(expired_result["address_line1"]).to eq("11 Some Unit")
        expect(expired_result["address_id"]).to eq("RRN-1000-0000-0000-0000-0001")
        expect(expired_result_xml.at("//CEPC:Property-Address//CEPC:Address-Line-1").text).to eq("11 Some Unit")
      end
    end

    it "loads RdSAPs into the database" do
      seventh_result = exported_data[6]
      expect(seventh_result["type_of_assessment"]).to eq("RdSAP")
      expect(seventh_result["current_energy_efficiency_rating"]).to eq(92)
    end

    it "loads the xml from the factory" do
      expect { UseCase::AssessmentSummary::Fetch.new.execute("0000-0000-0000-0000-0001") }.not_to raise_error
    end
  end
end
