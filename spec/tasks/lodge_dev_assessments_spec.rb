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
      get_task("dev_data:lodge_dev_assessments").invoke
    end

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments ORDER BY assessment_id")
    end

    it "loads the seed data into the database" do
      expect(exported_data.rows.length).to eq(17)
      first_result = exported_data.first
      expect(first_result["type_of_assessment"]).to eq("CEPC")
      expect(first_result["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      expect(first_result["scheme_assessor_id"]).to eq("RAKE000001")
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
