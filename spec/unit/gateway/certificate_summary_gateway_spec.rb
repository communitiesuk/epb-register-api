describe Gateway::CertificateSummaryGateway, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  before do
    add_countries
    add_super_assessor(scheme_id:)
    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
    domestic_sap_xml.at("RRN").content = "0000-0000-0000-0000-0001"
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )
    lodge_assessment(
      assessment_body: domestic_sap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "SAP-Schema-19.0.0",
      migrated: true,
    )
    load_green_deal_data
  end

  before(:all) do
    Timecop.freeze(2021, 2, 22, 0, 0, 0)
  end

  after(:all) do
    Timecop.return
  end

  describe "#fetch" do
    it "returns the expected data for a RdSAP certificate" do
      result = gateway.fetch("0000-0000-0000-0000-0000")
      expect(result.count).to eq(16)
    end

    it "returns the expected data for a SAP certificate" do
      result = gateway.fetch("0000-0000-0000-0000-0001")
      expect(result.count).to eq(16)
    end

    it "returns the expected data where a green deal is present" do
      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1111",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABC654321DEF",
      )
      result = gateway.fetch("0000-0000-0000-0000-1111")
      expect(result.count).to eq(16)
    end
  end
end
