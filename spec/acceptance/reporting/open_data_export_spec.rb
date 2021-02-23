def read_csv_fixture(file_name)
  # TODO: update the path to be more dynamic
  fixture_path = File.dirname __FILE__.gsub("acceptance/reporting", "")
  fixture_path << "/fixtures/open_data_export/csv/"
  read_file = File.read("#{fixture_path}#{file_name}.csv")
  CSV.parse(read_file, headers: true)
end

def get_fixture_headers(fixture_csv)
  fixture_csv.headers.compact.collect(&:strip)
end

def test_date
  "2021-02-22"
end

def get_exported_data_headers(exported_data)
  firstline = exported_data.split("\n")[0]
  firstline.split(",")
end

def missing_headers(
  fixture_header_array,
  exported_header_array,
  escape_headers = []
)
  escaped_array = fixture_header_array - escape_headers
  escaped_array.reject { |item| exported_header_array.include?(item) }
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
    cepc_rr_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc+rr")
    cepc_rr_xml
      .xpath("//*[local-name() = 'RRN']")
      .each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index + 2}"
      end

    cepc_rr_xml
      .xpath("//*[local-name() = 'Related-RRN']")
      .reverse
      .each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index + 2}"
      end

    cepc_rr_xml
      .xpath("//*[local-name() = 'Registration-Date']")
      .reverse
      .each { |node| node.content = Date.today.strftime("%F") }

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

    non_domestic_assessment_date.children = test_date
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    non_domestic_assessment_date.children = test_date
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

    non_domestic_assessment_date.children = test_date
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

    dec_assessment_date.children = test_date
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

    domestic_rdsap_assessment_date.children = test_date
    domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0004"
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )

    lodge_assessment(
      assessment_body: cepc_rr_xml.to_xml,
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

  context "when given the incorrect assessment type" do
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
    let(:use_case) { UseCase::ExportOpenDataCommercial.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(test_date)) }
    let(:fixture_csv) { read_csv_fixture("commerical") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }
    let(:fixture_csv_headers) do
      fixture_csv.headers - %w[
        RENEWABLE_SOURCES
        OTHER_FUEL_DESCRIPTION
        PRIMARY_ENERGY
      ]
    end

    it "returns an empty array when there are no missing headers in the exported data based on the fixture" do
      expect(fixture_csv_headers - parsed_exported_data.headers).to eq([])
    end
  end

  context "When we call the use case to extract the DEC data" do
    let(:dec_use_case) { UseCase::ExportOpenDataDec.new }
    let(:csv_data) do
      Helper::ExportHelper.to_csv(dec_use_case.execute(test_date))
    end
    let(:export_data_headers_array) { get_exported_data_headers(csv_data) }
    let(:fixture_csv) { read_csv_fixture("dec") }

    let(:fixture_headers_array) { get_fixture_headers(fixture_csv) }

    let(:ignore_headers) do
      %w[
        OPERATIONAL_RATING_BAND
        HEATING_CO2RENEWABLES_CO2
        NOMINATED-DATE"
        OR-ASSESSMENT-END-DATE
        OTHER_FUEL
        OCCUPANCY-LEVEL
        TYPICAL_THERMAL_FUEL_USAGE
        NOMINATED-DATE
      ]
    end

    it "returns an empty array when there are no missing headers in the exported data based on the fixture" do
      expect(
        missing_headers(
          fixture_headers_array,
          export_data_headers_array,
          ignore_headers,
        ),
      ).to eq([])
    end
  end

  context "When we call the use case to extract the domestic data" do
    let(:use_case) { UseCase::ExportOpenDataDomestic.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(test_date)) }
    let(:fixture_csv) { read_csv_fixture("domestic") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

    it "returns the data exported to a csv object to match the .csv fixture " do
      expect(parsed_exported_data.length).to eq(fixture_csv.length)
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
      expect(parsed_exported_data.first.to_a - fixture_csv.first.to_a).to eq([])
    end
  end

  context "When we call the use case to extract the domestic recommendations data" do
    let(:use_case) { UseCase::ExportOpenDataDomesticrr.new }
    let(:flattened_data) do
      Helper::ExportHelper.flatten_domestic_rr_response(
        use_case.execute(test_date),
      )
    end
    let(:csv_data) { Helper::ExportHelper.to_csv(flattened_data) }

    let(:csv_export_data_headers_array) do
      Helper::ExportHelper.convert_header_values(
        get_exported_data_headers(csv_data),
      ).sort
    end
    let(:fixture_csv) { read_csv_fixture("domestic_rr") }
    let(:fixture_headers_array) { get_fixture_headers(fixture_csv).sort }

    it "returns an empty array when there are no missing headers in the exported data based on the fixture" do
      expect(csv_export_data_headers_array).to eq(fixture_headers_array)
    end
  end

  context "When we call the use case to extract the Non Domestic RR data" do
    let(:use_case) { UseCase::ExportOpenDataCepcrr.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(test_date)) }
    let(:export_data_headers_array) { get_exported_data_headers(csv_data) }
    let(:fixture_csv) { read_csv_fixture("non_domestic_rr") }
    let(:fixture_headers_array) { get_fixture_headers(fixture_csv) }

    let(:ignore_headers) { %w[ASSESSMENT_ID] }

    it "returns an empty array when there are no missing headers in the exported data based on the fixture" do
      expect(
        missing_headers(
          fixture_headers_array,
          export_data_headers_array,
          ignore_headers,
        ),
      ).to eq([])
    end
  end
end
