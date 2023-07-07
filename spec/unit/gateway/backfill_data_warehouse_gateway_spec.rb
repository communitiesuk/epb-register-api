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
  end

  after do
    Timecop.return
  end

  describe "#get_rrn_date" do
    context "when searching for an rrn present in the assessments database" do
      it "returns a single assessment" do
        result = gateway.get_rrn_date("0000-0000-0000-0000-0001")
        expect(result.first["date_registered"]).to eq("2020-05-04")
      end
    end

    context "when searching for an rrn not present in the assessment database" do
      it "returns does not return an assessment" do
        result = gateway.get_rrn_date("0000-0000-0000-0000-0000")
        expect(result.count).to eq(0)
      end
    end
  end

  describe "#count_assessments_to_export" do
    context "when assessments are within the date range" do
      it "correctly counts how many assessments of the schema type to export" do
        result = gateway.count_assessments_to_export("2020-05-04", "2020-05-01", "RdSAP-Schema-20.0.0")
        expect(result).to eq(2)
      end
    end

    context "when there are no assessments of that schema in the date range" do
      it "gives a count of 0" do
        result = gateway.count_assessments_to_export("2020-05-04", "2020-05-01", "SAP-Schema-18.0.0")
        expect(result).to eq(0)
      end
    end

    context "when no assessments are in the date range" do
      it "gives a count of 0" do
        result = gateway.count_assessments_to_export("2020-04-04", "2020-04-01", "RdSAP-Schema-20.0.0")
        expect(result).to eq(0)
      end
    end
  end

  describe "#get_assessments_id" do
    it "gets the assessment ids in the time range and schema" do
      result = gateway.get_assessments_id(rrn_date: "2020-05-04", start_date: "2020-05-01", schema_type: "RdSAP-Schema-20.0.0")
      expect(result).to eq(%w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002])
      expect(result).not_to include("0000-0000-0000-0000-0003")
      expect(result).not_to include("0000-0000-0000-0000-0004")
    end
  end
end
