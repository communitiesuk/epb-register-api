def read_csv_fixture(file_name)
  # TODO: update the path to be more dynamic
  fixture_path = File.dirname __FILE__.gsub("acceptance/reporting", "")
  fixture_path << "/fixtures/open_data_export/csv/"
  csv = CSV.open("#{fixture_path}#{file_name}.csv", headers: true)
  csv.read
end

def fixture_headers(fixture_csv)
  fixture_csv.headers.collect { |item| item ? item.strip : item }
end

def exported_data_headers(exported_data)
  firstline = exported_data.split("\n")[0]
  firstline.split(",")
end

def missing_headers(fixture_header_array, exported_header_array)
  fixture_header_array.select { |item| !exported_header_array.include?(item) }
end

describe "Acceptance::Reports::OpenDataExport" do
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

    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    domestic_rdsap_assessment_id = domestic_rdsap_xml.at("RRN")
    domestic_rdsap_assessment_date = domestic_rdsap_xml.at("Registration-Date")

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

    dec_assessment_date.children = Date.today.strftime("%F")
    dec_assessment_id.children = "0000-0000-0000-0000-0003"
    lodge_assessment(
      assessment_body: dec_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    domestic_rdsap_assessment_date.children = Date.today.strftime("%F")
    domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0004"
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
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

  context "When we call the use case to extract the commercial data" do
    let(:days_ago) { Date.today - 2 }
    let(:use_case) { UseCase::ExportOpenDataCommercial.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(days_ago)) }
    let(:export_data_headers_array) { exported_data_headers(csv_data) }
    let(:fixture_csv) { read_csv_fixture("commerical") }

    let(:fixture_headers_array) { fixture_headers(fixture_csv) }

    let(:known_outstanding_nodes) do
      known_outstanding_nodes = %w[RENEWABLE_SOURCES]
    end

    it "there to be no missing headers in the exported data based on the fixture" do
      expect(
        missing_headers(fixture_headers_array, export_data_headers_array),
      ).to eq(known_outstanding_nodes)
    end
  end

  context "When we call the use case to extract the domestic data" do
    let(:days_ago) { Date.today - 2 }
    let(:use_case) { UseCase::ExportOpenDataDomestic.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(days_ago)) }
    let(:export_data_headers_array) { exported_data_headers(csv_data) }
    let(:fixture_csv) { read_csv_fixture("domestic") }

    let(:fixture_headers_array) { fixture_headers(fixture_csv) }

    let(:known_outstanding_nodes) { known_outstanding_nodes = "" }
  end
end
