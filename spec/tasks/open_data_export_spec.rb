describe "Rake open_data_export" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
    non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
    non_domestic_assessment_date =
      non_domestic_xml.at("//CEPC:Registration-Date")

    # Lodge a dec to ensure it is not exported
    dec_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
    dec_assessment_id = dec_xml.at("RRN")
    dec_assessment_date = dec_xml.at("Registration-Date")

    add_assessor(
      scheme_id,
      "SPEC000000",
      AssessorStub.new.fetch_request_body(
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "ACTIVE",
        nonDomesticDec: "ACTIVE",
        domesticRdSap: "ACTIVE",
        domesticSap: "ACTIVE",
        nonDomesticSp3: "ACTIVE",
        nonDomesticCc4: "ACTIVE",
        gda: "ACTIVE",
      ),
    )

    non_domestic_assessment_date.children = Date.today.strftime("%F")
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    non_domestic_assessment_date.children = Date.today.strftime("%F")
    non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    non_domestic_assessment_date.children = Date.today.strftime("%F")
    non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    dec_assessment_date.children = Date.today.strftime("%F")
    dec_assessment_id.children = "0000-0000-0000-0000-0005"
    lodge_assessment(
      assessment_body: dec_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )
  end

  let(:statistics) do
    gateway = Gateway::OpenDataLogGateway.new
    gateway.fetch_latest_statistics
  end

  let(:expected_output) { ~/A required argument is missing/ }

  context "when we call the invoke method without providing environment variables" do
    it "fails if no bucket or instance name is defined in environment variables" do
      expect { get_task("open_data_export").invoke }.to output(
        /#{expected_output}/,
      ).to_stderr
    end
  end

  context "When we call the invoke method without the storage configuration" do
    before do
      ENV["bucket_name"] = ""
      ENV["instance_name"] = ""
      ENV["date_from"] = DateTime.now.strftime("%F")
      ENV["assessment_type"] = "CEPC"
    end

    it "fails with correct error type" do
      expect { get_task("open_data_export").invoke }.to output(
        /Local AWS credentials or VCAP_SERVICES not present/,
      ).to_stderr
    end
  end

  context "when given the an incorrect environment variables" do
    before do
      ENV["bucket_name"] = "test_bucket"
      ENV["instance_name"] = "test_instance"
      ENV["date_from"] = DateTime.now.strftime("%F")
      ENV["assessment_type"] = "TEST"
    end

    it "fails if assessment is not of a valid type" do
      expect { get_task("open_data_export").invoke }.to output(
        /Assessment type is not valid:/,
      ).to_stderr
    end
  end

  context "When we call the invoke method with future data" do
    before do
      ENV["bucket_name"] = "test_bucket"
      ENV["instance_name"] = "test_instance"
      future_date_from = Time.now + 60 * 86_400
      ENV["date_from"] = future_date_from.strftime("%F")
      ENV["assessment_type"] = "CEPC"
    end

    it "returns the expected error for no data being found" do
      expect { get_task("open_data_export").invoke }.to output(
        /no data to export/,
      ).to_stdout
    end
  end

  #TODO stub the csv of exported data and use it as the expectation agianst the export
  #TODO add a test that test the logging

end
