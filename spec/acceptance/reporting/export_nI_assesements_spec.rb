describe "Acceptance::Reports::ExportNIAssessments" do
  include RSpecRegisterApiServiceMixin

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
