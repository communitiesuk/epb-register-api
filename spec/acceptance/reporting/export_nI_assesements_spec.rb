describe "Acceptance::Reports::ExportNIAssessments" do
  include RSpecRegisterApiServiceMixin

  context "when calling rake to export NI data"

  let(:storage_gateway) { instance_double(Gateway::StorageGateway) }

  let(:ni_gateway) do
    instance_double(Gateway::ExportNiGateway)
  end

  let(:xml_gateway) do
    instance_double(Gateway::AssessmentsXmlGateway)
  end

  let(:bucket_name) { "bucket_name" }
  let(:instance_name) { "epb-s3-service" }

  before do
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("instance_name").and_return(instance_name)
    allow(ENV).to receive(:[]).with("bucket_name").and_return(bucket_name)

    # Prevents logging during tests
    allow($stdout).to receive(:puts)

    domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
    allow(ni_gateway).to receive(:fetch_assessments).with(%w[RdSAP SAP]).and_return([
                                                                                      { "assessment_id" => "0000-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000001", "opt_out" => false, "cancelled" => false },
                                                                                      { "assessment_id" => "8888-0000-0000-0000-0002", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000000" },
                                                                                      { "assessment_id" => "9999-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => nil },
                                                                                    ])
    allow(xml_gateway).to receive(:fetch).and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "RdSAP-Schema-NI-20.0.0" })
    allow(ApiFactory).to receive(:ni_assessments_gateway).and_return(ni_gateway)
    allow(ApiFactory).to receive(:assessments_xml_gateway).and_return(xml_gateway)
    allow(storage_gateway).to receive(:write_file)
    allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)
  end

  it "does not raise an error" do
    expect { get_task("data_export:ni_assessments").invoke(%w[RdSAP SAP]) }.not_to raise_error
  end

  # it "pass converted file to S3" do
  #   allow(Gateway::StorageGateway).to receive(:new).and_return(
  #     storage_gateway,
  #     )
  #   allow(storage_gateway).to receive(:write_file)
  #
  #   get_task("data_export:ni_assessments").invoke(%w[RdSAP SAP])
  #
  #   expect(storage_gateway).to have_received(:write_file).with(
  #     "open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
  #     csv_data,
  #     )
  # end

  it 'raises an error if no argument is passed' do
    expect { get_task("data_export:ni_assessments").invoke }.to raise_error(Boundary::ArgumentMissing)
  end
end
