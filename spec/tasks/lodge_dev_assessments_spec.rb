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

    it "loads the seed data into the database" do
      expect(exported_data.rows.length).to eq(51)
      first_result = exported_data.first
      expect(first_result["type_of_assessment"]).to eq("CEPC")
      expect(first_result["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      expect(first_result["scheme_assessor_id"]).to eq("RAKE000001")
      expect(first_result["address_line1"]).to eq("Some Unit")
      expect(first_result["address_line2"]).to eq("3 Unit Road")
      expect(first_result["address_line3"]).to eq("Some Area")
      expect(first_result["address_line4"]).to eq("Some County")
      expect(first_result["town"]).to eq("Townplace")
      expect(first_result["postcode"]).to eq("A0 0AA")
    end

    it "provides linked certificates with different expiry dates" do
      first_result = exported_data.first
      second_result = exported_data[1]
      expect(first_result["type_of_assessment"]).to eq("CEPC")
      expect(second_result["type_of_assessment"]).to eq("CEPC")
      expect(first_result["address_id"]).to eq second_result["address_id"]
      expect(first_result["date_of_expiry"]).to be > second_result["date_of_expiry"]
    end

    it "provides expired certificates" do
      third_result = exported_data[2]
      expect(third_result["type_of_assessment"]).to eq("CEPC")
      expect(third_result["date_of_expiry"]).to be < Time.now
      expect(third_result["address_line2"]).to eq("13 Unit Road")
      expect(third_result["address_id"]).to eq("UPRN-100000000008")
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

  context "when reading cepc data from fixture" do
    let!(:xml_doc) do
      Nokogiri.XML Samples.xml "CEPC-8.0.0", "cepc+rr"
    end

    it "gets the report type from the xpath used in the factory" do
      filter_results_for = "0000-0000-0000-0000-0000"
      filtered_results = xml_doc.remove_namespaces!.at("//*[RRN=\"#{filter_results_for}\"]/ancestor::Report")
      expect(xml_doc.at("//Energy-Assessor//Certificate-Number").text).to eq("SPEC000000")

      expect(filtered_results).not_to eq(nil)
    end
  end

  context "when reading SAP data from fixture" do
    let!(:xml_doc) do
      Nokogiri.XML Samples.xml "SAP-Schema-18.0.0", "epc"
    end

    it "gets the report type from the xpath used in the factory" do
      xml_doc.remove_namespaces!
      expect(xml_doc.at("//Certificate-Number").text).to eq("SPEC000000")
    end
  end
end
