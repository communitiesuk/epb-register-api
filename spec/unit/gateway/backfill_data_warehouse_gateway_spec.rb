describe Gateway::BackfillDataWarehouseGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  before(:all) do
    Timecop.freeze(2020, 6, 22, 0, 0, 0)
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id:)
    rdsap1_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    rdsap1_xml.at("RRN").children = "0000-0000-0000-0000-0001"
    lodge_assessment(
      assessment_body: rdsap1_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )

    rdsap2_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    rdsap2_xml.at("RRN").children = "0000-0000-0000-0000-0002"
    rdsap2_xml.at("Registration-Date").children = "2020-05-02"
    lodge_assessment(
      assessment_body: rdsap2_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )

    rdsap3_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    rdsap3_xml.at("RRN").children = "0000-0000-0000-0000-0003"
    rdsap3_xml.at("Registration-Date").children = "2020-05-17"
    lodge_assessment(
      assessment_body: rdsap3_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )

    sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
    sap_xml.at("RRN").children = "0000-0000-0000-0000-0004"
    sap_xml.at("Registration-Date").children = "2020-05-02"
    lodge_assessment(
      assessment_body: sap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "SAP-Schema-19.0.0",
      migrated: true,
    )

    old_rdsap1_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    old_rdsap1_xml.at("RRN").children = "0000-0000-0000-0000-0009"
    sap_xml.at("Registration-Date").children = "2020-04-02"
    lodge_assessment(
      assessment_body: rdsap1_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )

    ac_report = Nokogiri.XML Samples.xml "CEPC-8.0.0", "ac-report"
    ac_report.at("RRN").children = "0000-0000-0000-0000-0030"
    lodge_assessment(
      assessment_body: ac_report.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
      schema_name: "CEPC-8.0.0",
    )
  end

  after do
    Timecop.return
  end

  describe "#get_assessments_id" do
    it "gets the assessment ids in the time range and schema" do
      result = gateway.get_assessments_id(start_date: "2020-05-01", type_of_assessment: "RdSAP", end_date: "2020-05-04")
      expect(result.sort).to eq(%w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002])
    end

    it "gets the assessment ids for any schema" do
      result = gateway.get_assessments_id(start_date: "2020-05-01", end_date: "2020-05-04")
      expect(result.sort).to eq(%w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0004])
    end

    it "does not return the id for ac-report" do
      result = gateway.get_assessments_id(start_date: "2020-05-01", end_date: "2020-05-04")
      expect(result).not_to include("0000-0000-0000-0000-0030")
    end

    it "gets the assessment ids for any type until now" do
      result = gateway.get_assessments_id(start_date: "2020-05-01")
      expect(result.count).to eq(4)
    end
  end
end
