describe "Acceptance::Reports::ExportNIAssessments" do
  include RSpecRegisterApiServiceMixin

  context 'when exporting the exporting the data to a csv before the rake is called' do


    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case) { UseCase::ExportNiAssessments.new(export_ni_gateway: ni_gateway, xml_gateway: xml_gateway) }

    let(:csv_data) do
      Helper::ExportHelper.to_csv(
        use_case
          .execute(%w[RdSAP SAP])
          .sort_by! { |item| item[:assessment_id] },
        )
    end
    let(:fixture_csv) { read_ni_csv_fixture("domestic") }
    let(:parsed_exported_data) { CSV.parse(csv_data, headers: true) }
    before do
      domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
      domestic_ni_rdsap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
      allow(ni_gateway).to receive(:fetch_assessments).with(%w[RdSAP SAP]).and_return([
                                                                                        { "assessment_id" => "0000-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000001", "opt_out" => false, "cancelled" => false },
                                                                                        { "assessment_id" => "0000-0000-0000-0000-0002", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000000", "opt_out" => false, "cancelled" => false},

                                                                                      ])
      allow(xml_gateway).to receive(:fetch).with("0000-0000-0000-0000-0000").and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "SAP-Schema-NI-18.0.0" })
      allow(xml_gateway).to receive(:fetch).with("0000-0000-0000-0000-0002").and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "SAP-Schema-NI-18.0.0" })
    end

      it "returns a .csv of the correct number of rows s" do
        expect(parsed_exported_data.length).to eq(fixture_csv.length)
      end

      it "returns the data exported to a csv object to match the .csv fixture" do
        expect(parsed_exported_data.headers - fixture_csv.headers).to eq([])
      end


    end



  context 'when calling the the rake to export the Northern Ireland data' do
    subject(:task) { get_task("data_export:ni_assessments") }

    let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
    let(:ni_gateway) { instance_double(Gateway::ExportNiGateway) }
    let(:xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
    let(:use_case_export) { instance_double(UseCase::ExportNiAssessments) }
    let(:file_name) { "ni_assessments_export_rdsap_sap_#{DateTime.now.strftime('%F')}.csv" }
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
      task.invoke(%w[RdSAP SAP])

      expect(WebMock).to have_requested(
                           :put,
                           "#{HttpStub::S3_BUCKET_URI}#{file_name}",
                           ).with(body: "ASSESSMENT_ID,ADDRESS1,ADDRESS2\n9999-0000-0000-0000-0000,1 Some Street,\"\"\n",
                                  headers: {
                                    "Host" => "s3.eu-west-2.amazonaws.com",
                                  })
    end
  end
end


def read_ni_csv_fixture(file_name, parse: true)
  fixture_path = File.dirname __FILE__.gsub("acceptance/reporting", "")
  fixture_path << "/fixtures/ni_export/"
  read_file = File.read("#{fixture_path}#{file_name}.csv")
  CSV.parse(read_file, headers: true) if parse
end
