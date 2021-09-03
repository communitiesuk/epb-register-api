describe "Acceptance::Reports::ExportNIAssessments" do
  include RSpecRegisterApiServiceMixin

  after { WebMock.disable! }

  context "when calling rake to export NI data"

  let(:ni_gateway) do
    instance_double(Gateway::ExportNiGateway)
  end

  let(:xml_gateway) do
    instance_double(Gateway::AssessmentsXmlGateway)
  end

  it "does not raise an error" do
    domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
    allow(ni_gateway).to receive(:fetch_assessments).with(%w[RdSAP SAP]).and_return([
      { "assessment_id" => "0000-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000001", "opt_out" => false, "cancelled" => false },
      { "assessment_id" => "8888-0000-0000-0000-0002", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000000" },
      { "assessment_id" => "9999-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => nil },
    ])
    allow(xml_gateway).to receive(:fetch).and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "RdSAP-Schema-NI-20.0.0" })
    allow(ApiFactory).to receive(:ni_assessments_gateway).and_return(ni_gateway)
    allow(ApiFactory).to receive(:assessments_xml_gateway).and_return(xml_gateway)

    expect { get_task("data_export:ni_assessments").invoke }.not_to raise_error
  end
end
