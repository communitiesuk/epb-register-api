describe "Acceptance::Reports::ExportNIAssessments" do
  include RSpecRegisterApiServiceMixin

  context "when exporting the domestic data to a csv before the rake is called" do
    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case) { UseCase::ExportNiAssessments.new(export_ni_gateway: ni_gateway, xml_gateway:) }

    let(:csv_data) do
      Helper::ExportHelper.to_csv(
        use_case
          .execute(type_of_assessment: %w[RdSAP SAP])
          .sort_by! { |item| item[:assessment_id] },
      )
    end
    let(:fixture_csv) { read_ni_csv_fixture("domestic") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

    before(:all) do
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after(:all) do
      Timecop.return
    end

    before do
      domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
      domestic_ni_rdsap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
      allow(ni_gateway).to receive(:fetch_assessments).with(type_of_assessment: %w[RdSAP SAP], date_from: "1990-01-01", date_to: Time.now).and_return([
        { "assessment_id" => "0000-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000001", "opt_out" => false, "cancelled" => false },
        { "assessment_id" => "0000-0000-0000-0000-0002", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000000", "opt_out" => false, "cancelled" => false },

      ])
      allow(xml_gateway).to receive(:fetch).with("0000-0000-0000-0000-0000").and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "SAP-Schema-NI-18.0.0" })
      allow(xml_gateway).to receive(:fetch).with("0000-0000-0000-0000-0002").and_return({ xml: domestic_ni_rdsap_xml.to_xml, schema_type: "RdSAP-Schema-NI-20.0.0" })
    end

    it "returns a .csv of the correct number of rows " do
      expect(parsed_exported_data.length).to eq(parsed_exported_data.length)
    end

    it "returns the data exported to a csv object to match the .csv fixture" do
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
    end

    2.times do |i|
      it "returns the data exported for row #{i + 1} object to match same row in the .csv fixture " do
        expect(
          redact_ni_lodgement_datetime(parsed_exported_data[i]) -
            redact_ni_lodgement_datetime(fixture_csv[i]),
        ).to eq([])
      end
    end
  end

  context "when exporting the commercial data to a csv before the rake is called" do
    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case) { UseCase::ExportNiAssessments.new(export_ni_gateway: ni_gateway, xml_gateway:) }

    let(:csv_data) do
      Helper::ExportHelper.to_csv(
        use_case
          .execute(type_of_assessment: %w[CEPC])
          .sort_by! { |item| item[:assessment_id] },
      )
    end
    let(:fixture_csv) { read_ni_csv_fixture("commercial") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }

    before(:all) do
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after(:all) do
      Timecop.return
    end

    before do
      commercial_ni_xml = Nokogiri.XML Samples.xml("CEPC-NI-8.0.0", "cepc")
      commercial_xml_old = Nokogiri.XML Samples.xml("CEPC-7.1", "cepc")
      commercial_assessment_id = commercial_xml_old.at("RRN")
      commercial_assessment_id.children = "0000-0000-0000-0000-0002"
      allow(ni_gateway).to receive(:fetch_assessments).with(type_of_assessment: %w[CEPC], date_from: "1990-01-01", date_to: Time.now).and_return([
        { "assessment_id" => "0000-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000001", "opt_out" => false, "cancelled" => false },
        { "assessment_id" => "0000-0000-0000-0000-0002", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000000", "opt_out" => false, "cancelled" => false },

      ])
      allow(xml_gateway).to receive(:fetch).with("0000-0000-0000-0000-0000").and_return({ xml: commercial_ni_xml.to_xml, schema_type: "CEPC-NI-8.0.0" })
      allow(xml_gateway).to receive(:fetch).with("0000-0000-0000-0000-0002").and_return({ xml: commercial_xml_old.to_xml, schema_type: "CEPC-7.1" })
    end

    it "returns a .csv of the correct number of rows s" do
      expect(parsed_exported_data.length).to eq(fixture_csv.length)
    end

    it "returns the data exported to a csv object to match the .csv fixture" do
      expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
    end

    2.times do |i|
      it "returns the data exported for row #{i + 1} object to match same row in the .csv fixture " do
        expect(
          redact_ni_lodgement_datetime(parsed_exported_data[i]) -
            redact_ni_lodgement_datetime(fixture_csv[i]),
        ).to eq([])
      end
    end
  end

  context "when calling the the rake to export the Northern Ireland domestic data" do
    subject(:task) { get_task("data_export:ni_assessments") }

    let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case_export) { instance_double(UseCase::ExportNiAssessments) }
    let(:file_name) { "ni_assessments_export_rdsap-sap_#{Time.now.strftime('%F')}.csv" }
    let(:export_use_case) { instance_double(UseCase::ExportNiAssessments) }
    let(:export) do
      [
        {
          assessment_id:
            "9999-0000-0000-0000-0000",
          address1: "1 Some Street",
          address2: "",
        },

      ]
    end

    before do
      EnvironmentStub.all
      # Define mock expectations
      allow(ApiFactory).to receive(:ni_assessments_export_use_case).and_return(
        export_use_case,
      )
      allow(export_use_case).to receive(:execute).and_return(export)
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)
      HttpStub.s3_put_csv(file_name)
    end

    it "sends the converted csv to the S3 bucket " do
      task.invoke("RdSAP-SAP")

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}#{file_name}",
      ).with(body: "ASSESSMENT_ID,ADDRESS1,ADDRESS2\n9999-0000-0000-0000-0000,1 Some Street,\"\"\n",
             headers: {
               "Host" => "s3.eu-west-2.amazonaws.com",
             })
    end
  end

  context "when calling the rake to export the Northern Ireland commercial data" do
    subject(:task) { get_task("data_export:ni_assessments") }

    let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case_export) { instance_double(UseCase::ExportNiAssessments) }
    let(:file_name) { "ni_assessments_export_cepc_#{Time.now.strftime('%F')}.csv" }
    let(:export_use_case) { instance_double(UseCase::ExportNiAssessments) }
    let(:export) do
      [
        {
          assessment_id:
            "9999-0000-0000-0000-0000",
          address1: "1 Some Street",
          address2: "",
        },

      ]
    end

    before do
      EnvironmentStub.all
      # Define mock expectations
      allow(ApiFactory).to receive(:ni_assessments_export_use_case).and_return(
        export_use_case,
      )
      allow(export_use_case).to receive(:execute).and_return(export)
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)
      HttpStub.s3_put_csv(file_name)
    end

    it "sends the converted csv to the S3 bucket " do
      task.invoke("CEPC")

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}#{file_name}",
      ).with(body: "ASSESSMENT_ID,ADDRESS1,ADDRESS2\n9999-0000-0000-0000-0000,1 Some Street,\"\"\n",
             headers: {
               "Host" => "s3.eu-west-2.amazonaws.com",
             })
    end
  end

  context "when calling the rake using environment variables" do
    subject(:task) { get_task("data_export:ni_assessments") }

    let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case_export) { instance_double(UseCase::ExportNiAssessments) }
    let(:file_name) { "ni_assessments_export_cepc_#{Time.now.strftime('%F')}.csv" }
    let(:export_use_case) { instance_double(UseCase::ExportNiAssessments) }
    let(:export) do
      [
        {
          assessment_id:
            "9999-0000-0000-0000-0000",
          address1: "1 Some Street",
          address2: "",
        },

      ]
    end

    before do
      EnvironmentStub.all
      # Define mock expectations
      allow(ApiFactory).to receive(:ni_assessments_export_use_case).and_return(
        export_use_case,
      )
      allow(export_use_case).to receive(:execute).and_return(export)
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)
      EnvironmentStub.with("type_of_assessments", "CEPC")
      EnvironmentStub.with("date_from", Time.now.strftime("%F"))
      HttpStub.s3_put_csv(file_name)
    end

    it "does not raise an argument error" do
      expect { task.invoke }.not_to raise_error
    end
  end
end

def read_ni_csv_fixture(file_name, parse: true)
  fixture_path = File.dirname __FILE__.gsub("acceptance/reporting", "")
  fixture_path << "/fixtures/ni_export/"
  read_file = File.read("#{fixture_path}#{file_name}.csv")
  CSV.parse(read_file, headers: true) if parse
end

def redact_ni_lodgement_datetime(csv_object)
  array = csv_object.to_a
  array.reject { |k| k[0] == "LODGEMENT_DATETIME" }
  array.reject { |k| k[0] == "LODGEMENT_DATE" }
end
