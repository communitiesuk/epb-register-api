describe "Acceptance::Reports::OpenDataExport" do
  include RSpecRegisterApiServiceMixin

  after { WebMock.disable! }

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

    domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
    domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
    domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")
    domestic_sap_building_reference_number = domestic_sap_xml.at("UPRN")

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
      .each { |node| node.content = test_date }

    dec_rr_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec+rr")
    dec_rr_xml
      .xpath("//*[local-name() = 'RRN']")
      .each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index + 4}"
      end

    dec_rr_xml
      .xpath("//*[local-name() = 'Related-RRN']")
      .reverse
      .each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index + 4}"
      end

    dec_rr_xml
      .xpath("//*[local-name() = 'Registration-Date']")
      .reverse
      .each { |node| node.content = test_date }

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

    lodge_assessment(
      assessment_body: dec_rr_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    domestic_sap_assessment_date.children = test_date
    domestic_sap_assessment_id.children = "0000-0000-0000-0000-1100"
    domestic_sap_building_reference_number.children =
      "RRN-0000-0000-0000-0000-0023"
    lodge_assessment(
      assessment_body: domestic_sap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "SAP-Schema-18.0.0",
    )
  end

  let(:statistics) do
    gateway = Gateway::OpenDataLogGateway.new
    gateway.fetch_latest_statistics
  end

  let(:expected_output) { ~/A required argument is missing/ }

  context "when we call the invoke method without providing environment variables" do
    before do
      EnvironmentStub
        .all
        .except("BUCKET_NAME")
        .except("DATE_FROM")
        .except("ASSESSMENT_TYPE")
    end

    it "fails if no bucket or instance name is defined in environment variables" do
      expect { get_task("open_data_export").invoke }.to output(
        /#{expected_output}/,
      ).to_stderr
    end
  end

  context "when given the incorrect assessment type" do
    before do
      EnvironmentStub
        .all
        .with("DATE_FROM", DateTime.now.strftime("%F"))
        .with("ASSESSMENT_TYPE", "TEST")
    end

    it "returns the type is not valid error message" do
      expect { get_task("open_data_export").invoke }.to output(
        /Assessment type is not valid:/,
      ).to_stderr
    end
  end

  context "when given the correct environment variables but an invalid date" do
    before do
      EnvironmentStub
        .all
        .with("DATE_FROM", DateTime.now.strftime("%F"))
        .with("ASSESSMENT_TYPE", "SAP-RDSAP")
    end

    it "returns a no data to extract error" do
      expect { get_task("open_data_export").invoke }.to output(
        /no data to export/,
      ).to_stdout
    end
  end

  context "when given the incorrect environment variables invoke the task" do
    before do
      EnvironmentStub
        .all
        .with("DATE_FROM", test_date)
        .with("ASSESSMENT_TYPE", "CEPC")
    end

    it "returns an AWS error when connecting to the live S3 gateway" do
      WebMock.disable!
      expect { get_task("open_data_export").invoke }.to raise_error(/AWS/)
    end
  end

  context "when given the correct environment variables invoke the task to send the domestic data to S3" do
    before do
      EnvironmentStub
        .all
        .with("DATE_FROM", test_date)
        .with("ASSESSMENT_TYPE", "SAP-RDSAP")

      WebMock.enable!
      WebMock.reset!
      HttpStub.s3_put_csv(file_name)
    end
    let(:fixture_csv) { read_csv_fixture("domestic") }

    let(:file_name) do
      "open_data_export_#{ENV['ASSESSMENT_TYPE'].downcase}_#{DateTime.now.strftime('%F')}_1.csv"
    end

    let(:regex_body_pattern) do
      str = ""
      fixture_csv.headers.each { |item| str << "(?=^.*?#{item}.*$)" }
      Regexp.new("#{str}.*$")
    end

    it "mocks the HTTP Request of the storage gateway and checks the client request was processed" do
      get_task("open_data_export").invoke

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}#{file_name}",
      ).with(
        body: regex_body_pattern,
        headers: {
          "Host" => "s3.eu-west-2.amazonaws.com",
        },
      )
    end
  end

  context "when given the correct environment variables invoke the task to send the domestic rr data to S3" do
    before do
      EnvironmentStub
        .all
        .with("DATE_FROM", test_date)
        .with("ASSESSMENT_TYPE", "SAP-RDSAP-RR")

      WebMock.enable!
      WebMock.reset!
      HttpStub.s3_put_csv(file_name)
    end
    let(:fixture_csv) { read_csv_fixture("domestic_rr") }

    let(:file_name) do
      "open_data_export_#{ENV['ASSESSMENT_TYPE'].downcase}_#{DateTime.now.strftime('%F')}_1.csv"
    end

    let(:regex_body_pattern) do
      str = ""
      fixture_csv.headers.each { |item| str << "(?=^.*?#{item}.*$)" }
      Regexp.new("#{str}.*$")
    end

    it "mocks the HTTP Request of the storage gateway and checks the client request was processed" do
      get_task("open_data_export").invoke

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}#{file_name}",
      ).with(
        body: regex_body_pattern,
        headers: {
          "Host" => "s3.eu-west-2.amazonaws.com",
        },
      )
    end
  end

  context "when given the correct environment variables invoke the task to send the commercial rr data to S3" do
    before do
      EnvironmentStub
        .all
        .with("DATE_FROM", test_date)
        .with("ASSESSMENT_TYPE", "CEPC-RR")

      WebMock.enable!
      WebMock.reset!
      HttpStub.s3_put_csv(file_name)
    end
    let(:fixture_csv) { read_csv_fixture("commercial_rr") }

    let(:file_name) do
      "open_data_export_#{ENV['ASSESSMENT_TYPE'].downcase}_#{DateTime.now.strftime('%F')}_1.csv"
    end

    let(:regex_body_pattern) do
      str = ""
      fixture_csv.headers.each { |item| str << "(?=^.*?#{item}.*$)" }
      Regexp.new("#{str}.*$")
    end

    it "mocks the HTTP Request of the storage gateway and checks the client request was processed" do
      get_task("open_data_export").invoke

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}#{file_name}",
      ).with(
        body: regex_body_pattern,
        headers: {
          "Host" => "s3.eu-west-2.amazonaws.com",
        },
      )
    end
  end

  # TODO: once the nodes are complete update to test for content as well as headers
  context "When we call the use case to extract the commercial/non-domestic data" do
    let(:use_case) { UseCase::ExportOpenDataCommercial.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(test_date)) }
    let(:fixture_csv) { read_csv_fixture("commercial") }
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

  context "When we call the use case to extract the commercial/non Domestic RR data" do
    let(:use_case) { UseCase::ExportOpenDataCepcrr.new }
    let(:csv_data) { Helper::ExportHelper.to_csv(use_case.execute(test_date)) }
    let(:fixture_csv) { read_csv_fixture("commercial_rr") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }
    let(:ignore_headers) { %w[ASSESSMENT_ID] }

    it "returns the data exported to a csv object to match the .csv fixture " do
      expect(parsed_exported_data.length).to eq(fixture_csv.length)
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
    end

    5.times do |i|
      it "returns the data exported for row #{i} object to match same row in the .csv fixture " do
        expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq([])
      end
    end
  end

  # TODO: Test content as well as headers
  context "When we call the use case to extract the DEC data" do
    let(:dec_use_case) { UseCase::ExportOpenDataDec.new }
    let(:csv_data) do
      Helper::ExportHelper.to_csv(dec_use_case.execute(test_date))
    end

    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

    let(:fixture_csv) { read_csv_fixture("dec") }

    it "returns the data exported to a csv object to match the .csv fixture " do
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
    end
  end

  context "When we call the use case to extract the DEC RR data" do
    let(:use_case) { UseCase::ExportOpenDataDecrr.new }
    let(:csv_data) do
      Helper::ExportHelper.to_csv(
        use_case.execute(test_date).sort_by! { |key| key[:recommendation_item] },
      )
    end
    let(:export_data_headers_array) { get_exported_data_headers(csv_data) }
    let(:fixture_csv) { read_csv_fixture("dec_rr") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }
    let(:ignore_headers) { %w[ASSESSMENT_ID] }

    it "returns the data exported to a csv object to match the .csv fixture " do
      expect(parsed_exported_data.length).to eq(fixture_csv.length)
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
    end

    5.times do |i|
      it "returns the data exported for row #{i} object to match same row in the .csv fixture " do
        expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq([])
      end
    end
  end

  context "When we call the use case to extract the domestic data" do
    let(:use_case) { UseCase::ExportOpenDataDomestic.new }
    let(:csv_data) do
      Helper::ExportHelper.to_csv(
        use_case.execute(test_date).sort_by! { |item| item[:assessment_id] },
      )
    end
    let(:fixture_csv) { read_csv_fixture("domestic") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

    it "returns the data exported to a csv object to match the .csv fixture " do
      expect(parsed_exported_data.length).to eq(fixture_csv.length)
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
    end

    2.times do |i|
      it "returns the data exported for row #{i} object to match same row in the .csv fixture " do
        expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq([])
      end
    end
  end

  context "When we call the use case to extract the domestic recommendations data" do
    let(:use_case) { UseCase::ExportOpenDataDomesticrr.new }
    let(:csv_data) do
      Helper::ExportHelper.to_csv(
        use_case
          .execute(test_date)
          .sort_by! { |item| [item[:assessment_id], item[:improvement_item]] },
      )
    end
    let(:fixture_csv) { read_csv_fixture("domestic_rr") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

    it "returns the data exported to a csv object to match the .csv fixture " do
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
      expect(parsed_exported_data.length).to eq(fixture_csv.length)
    end

    4.times do |i|
      it "returns the data exported for row #{i} object to match same row in the .csv fixture " do
        expect(parsed_exported_data[i].to_a - fixture_csv[i].to_a).to eq([])
      end
    end
  end
end

private

def test_date
  "2021-02-22"
end
