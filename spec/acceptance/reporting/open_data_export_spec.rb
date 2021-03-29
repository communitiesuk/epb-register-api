require_relative "open_data_export_test_helper"

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
      .each { |node| node.content = test_start_date }

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
      .each { |node| node.content = test_start_date }

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

    non_domestic_assessment_date.children = test_start_date
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
    )

    non_domestic_assessment_date.children = test_start_date
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

    non_domestic_assessment_date.children = test_to_date
    non_domestic_assessment_id.children = "0000-0000-0000-0000-0010"
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
      )

    dec_assessment_date.children = test_start_date
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

    dec_assessment_date.children = test_to_date
    dec_assessment_id.children = "0000-0000-0000-0000-0012"
    lodge_assessment(
      assessment_body: dec_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
      )

    domestic_rdsap_assessment_date.children = test_start_date
    domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0004"
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )

    domestic_rdsap_assessment_date.children = test_to_date
    domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-1004"
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

    cepc_rr_xml
      .xpath("//*[local-name() = 'RRN']")
      .each_with_index do |node, index|
      node.content = "1112-0000-0000-0000-000#{index + 2}"
    end
    cepc_rr_xml
      .xpath("//*[local-name() = 'Related-RRN']")
      .reverse
      .each_with_index do |node, index|
      node.content = "1112-0000-0000-0000-000#{index + 2}"
    end
    cepc_rr_xml
      .xpath("//*[local-name() = 'Registration-Date']")
      .reverse
      .each { |node| node.content = test_to_date }

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

    dec_rr_xml
      .xpath("//*[local-name() = 'RRN']")
      .each_with_index do |node, index|
      node.content = "1112-0000-0000-0000-000#{index + 4}"
    end

    dec_rr_xml
      .xpath("//*[local-name() = 'Related-RRN']")
      .reverse
      .each_with_index do |node, index|
      node.content = "1112-0000-0000-0000-000#{index + 4}"
    end

    dec_rr_xml
      .xpath("//*[local-name() = 'Registration-Date']")
      .reverse
      .each { |node| node.content = test_to_date }

    lodge_assessment(
      assessment_body: dec_rr_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
      schema_name: "CEPC-8.0.0",
      )


    domestic_sap_assessment_date.children = test_start_date
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

  context "When data returned from the use case is converted into a csv" do
    context "Call the use case to extract the commercial/non-domestic data" do
      let(:use_case) { UseCase::ExportOpenDataCommercial.new }
      let(:csv_data) do
        Helper::ExportHelper.to_csv(use_case.execute(test_start_date, 0, "2021-02-28"))
      end
      let(:fixture_csv) { read_csv_fixture("commercial") }
      let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

      let(:first_commercial_assesment) do
        parsed_exported_data.find do |item|
          item["ASSESSMENT_ID"] ==
            "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"
        end
      end

      let(:second_commercial_assesment) do
        parsed_exported_data.find do |item|
          item["ASSESSMENT_ID"] ==
            "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"
        end
      end

      it "returns an empty array when there are no missing headers in the exported data based on the fixture" do
        expect(fixture_csv.headers - parsed_exported_data.headers).to eq([])
        expect(parsed_exported_data.length).to eq(3)
      end

      it "returns the data exported for row 1 object to match same row in the .csv fixture " do
        expect(first_commercial_assesment.to_a - fixture_csv[0].to_a).to eq([])
      end

      it "returns the data exported for row 2 object to match same row in the .csv fixture " do
        expect(second_commercial_assesment.to_a - fixture_csv[0].to_a).to eq([])
      end
    end

    context "Call the use case to extract the commercial/non Domestic RR data" do
      let(:use_case) { UseCase::ExportOpenDataCepcrr.new }
      let(:csv_data) do
        Helper::ExportHelper.to_csv(use_case.execute(test_start_date, 0, "2021-02-28"))
      end
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

    context "Call the use case to extract the DEC data" do
      let(:dec_use_case) { UseCase::ExportOpenDataDec.new }
      let(:csv_data) do
        Helper::ExportHelper.to_csv(dec_use_case.execute(test_start_date, 0, "2021-02-28"))
      end

      let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

      let(:fixture_csv) { read_csv_fixture("dec") }

      it "returns the data exported to a csv object to match the .csv fixture " do
        expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
        expect(parsed_exported_data.length).to eq(fixture_csv.length)
      end

      let(:first_dec_asssement) do
        parsed_exported_data.find do |item|
          item["ASSESSMENT_ID"] ==
            "36ae715ec66a32ed9ffcd7fe9a2c44d91dec1d72ee26263c17f354167be8dd4b"
        end
      end

      let(:second_dec_asssement) do
        parsed_exported_data.find do |item|
          item["ASSESSMENT_ID"] ==
            "427ad45e88b1183572234b464ba07b37348243d120db1c478da42eda435e48e4"
        end
      end
      it "returns the data exported for row 1 object to match same row in the .csv fixture " do
        expect(first_dec_asssement.to_a - fixture_csv[0].to_a).to eq([])
      end

      it "returns the data exported for row 2 to match same row in the .csv fixture " do
        expect(second_dec_asssement.to_a - fixture_csv[1].to_a).to eq([])
      end
    end

    context "Call the use case to extract the DEC RR data" do
      let(:use_case) { UseCase::ExportOpenDataDecrr.new }
      let(:csv_data) do
        Helper::ExportHelper.to_csv(
          use_case
            .execute(test_start_date, 0, "2021-02-28")
            .sort_by! { |key| key[:recommendation_item] },
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

    context "Call the use case to extract the domestic data" do
      let(:use_case) { UseCase::ExportOpenDataDomestic.new }
      let(:csv_data) do
        Helper::ExportHelper.to_csv(
          use_case.execute(test_start_date, 0, "2021-02-28").sort_by! { |item| item[:assessment_id] },
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

    context "Call the use case to extract the domestic recommendations data" do
      let(:use_case) { UseCase::ExportOpenDataDomesticrr.new }
      let(:csv_data) do
        Helper::ExportHelper.to_csv(
          use_case
            .execute(test_start_date, 0, "2021-02-28")
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

  context "When invoking the Open Data Communities export rake directly" do
    context "provide environment variables" do
      before do
        EnvironmentStub
          .all
          .except("BUCKET_NAME")
          .except("DATE_FROM")
          .except("ASSESSMENT_TYPE")
      end

      it "fails if no bucket or instance name is defined in environment variables" do
        expect { get_task("open_data_export").invoke }.to output(
          /A required argument is missing/,
        ).to_stderr
      end
    end

    context "Set the incorrect assessment type environment variable" do
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

    context "Set the correct environment variables and a date of now" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", DateTime.now.strftime("%F"))
          .with("ASSESSMENT_TYPE", "SAP-RDSAP")
      end

      it "returns a no data to export error" do
        expect { get_task("open_data_export").invoke }.to output(
          /No data provided for export/,
        ).to_stderr
      end
    end

    context "Set the correct environment variables invoke the task to send the domestic data to S3" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", test_start_date)
          .with("ASSESSMENT_TYPE", "SAP-RDSAP")

        HttpStub.s3_put_csv(file_name("SAP-RDSAP"))
      end
      let(:fixture_csv) { read_csv_fixture("domestic") }

      it "check the http stub matches the request disabled in web mock using the filename, body and headers " do
        get_task("open_data_export").invoke

        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_sap-rdsap_#{DateTime.now.strftime('%F')}_1.csv",
        ).with(
          body: regex_body(fixture_csv.headers),
          headers: {
            "Host" => "s3.eu-west-2.amazonaws.com",
          },
        )
      end
    end

    context "Set the correct environment variables invoke the task to send the domestic rr data to S3" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", test_start_date)
          .with("ASSESSMENT_TYPE", "SAP-RDSAP-RR")

        HttpStub.s3_put_csv(file_name("SAP-RDSAP-RR"))
      end
      let(:fixture_csv) { read_csv_fixture("domestic_rr") }

      it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
        get_task("open_data_export").invoke

        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_sap-rdsap-rr_#{DateTime.now.strftime('%F')}_1.csv",
        ).with(
          body: regex_body(fixture_csv.headers),
          headers: {
            "Host" => "s3.eu-west-2.amazonaws.com",
          },
        )
      end
    end

    context "Set the correct environment variables invoke the task to send the commercial/non domestic data to S3" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", test_start_date)
          .with("ASSESSMENT_TYPE", "CEPC")
        HttpStub.s3_put_csv(file_name("CEPC"))
      end

      let(:fixture_csv) { read_csv_fixture("commercial") }

      it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
        get_task("open_data_export").invoke

        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_cepc_#{DateTime.now.strftime('%F')}_1.csv",
        ).with(
          body: regex_body(fixture_csv.headers),
          headers: {
            "Host" => "s3.eu-west-2.amazonaws.com",
          },
        )
      end
    end

    context "Set the correct environment variables invoke the task to send the commercial/non domestic rr data to S3" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", test_start_date)
          .with("ASSESSMENT_TYPE", "CEPC-RR")

        HttpStub.s3_put_csv(file_name("CEPC-RR"))
      end
      let(:fixture_csv) { read_csv_fixture("commercial_rr") }

      it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
        get_task("open_data_export").invoke

        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_cepc-rr_#{DateTime.now.strftime('%F')}_1.csv",
        ).with(
          body: regex_body(fixture_csv.headers),
          headers: {
            "Host" => "s3.eu-west-2.amazonaws.com",
          },
        )
      end
    end

    context "Set the correct environment variables invoke the task to send the DEC data to S3" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", test_start_date)
          .with("ASSESSMENT_TYPE", "DEC")
        HttpStub.s3_put_csv(file_name("DEC"))
      end

      let(:regex_body_pattern) do
        fixture_headers = %w[
          YR1_ELECTRICITY_CO2,YR2_ELECTRICITY_CO2,YR1_HEATING_CO2,YR2_HEATING_CO2,YR1_RENEWABLES_CO2,YR2_RENEWABLES_CO2,AIRCON_PRESENT,AIRCON_KW_RATING,ESTIMATED_AIRCON_KW_RATING
        ]
        regex_body(fixture_headers)
      end

      it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
        get_task("open_data_export").invoke
        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_dec_#{DateTime.now.strftime('%F')}_1.csv",
        ).with(
          body: regex_body_pattern,
          headers: {
            "Host" => "s3.eu-west-2.amazonaws.com",
          },
        )
      end
    end

    context "Set the correct environment variables invoke the task to send the DEC RR data to S3" do
      before do
        EnvironmentStub
          .all
          .with("DATE_FROM", test_start_date)
          .with("ASSESSMENT_TYPE", "DEC-RR")
        HttpStub.s3_put_csv(file_name("DEC-RR"))
      end

      let(:fixture_csv) { read_csv_fixture("dec_rr") }

      it "check the http stub matches the request disabled in web mock using the filename, body and headers" do
        get_task("open_data_export").invoke
        expect(WebMock).to have_requested(
          :put,
          "#{HttpStub::S3_BUCKET_URI}open_data_export_dec-rr_#{DateTime.now.strftime('%F')}_1.csv",
        ).with(
          body: regex_body(fixture_csv.headers),
          headers: {
            "Host" => "s3.eu-west-2.amazonaws.com",
          },
        )
      end
    end
  end
end
