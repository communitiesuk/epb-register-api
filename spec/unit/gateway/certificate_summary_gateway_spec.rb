describe Gateway::CertificateSummaryGateway, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:xml_fixture) do
    Samples.xml("RdSAP-Schema-20.0.0")
  end

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
      expected_data_without_xml = {
        "created_at" => Time.utc(2021, 2, 22),
        "opt_out" => false,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "assessment_address_id" => "UPRN-000000000000",
        "country_name" => "Unknown",
        "scheme_assessor_id" => "SPEC000000",
        "scheme_id" => scheme_id,
        "assessor_first_name" => "Someone",
        "assessor_last_name" => "Person",
        "assessor_telephone_number" => "010199991010101",
        "assessor_email" => "person@person.com",
        "scheme_name" => "test scheme",
        "schema_type" => "RdSAP-Schema-20.0.0",
        "green_deal_plan_id" => nil,
        "count_address_id_assessments" => 1,
      }

      result = gateway.fetch("0000-0000-0000-0000-0000")
      expect(result.count).to eq(17)
      expect(result["xml"]).to be_a String
      expect(result).to include expected_data_without_xml
    end

    it "returns the expected data for a SAP certificate" do
      result = gateway.fetch("0000-0000-0000-0000-0001")
      expect(result.count).to eq(17)
    end

    it "returns the expected data where no green deal is present" do
      result = gateway.fetch("0000-0000-0000-0000-0000")
      expect(result["green_deal_plan_id"]).to be_nil
    end

    it "returns the expected data where a green deal is present" do
      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1111",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABC654321DEF",
      )
      result = gateway.fetch("0000-0000-0000-0000-1111")
      expect(result["green_deal_plan_id"]).to eq("ABC654321DEF")
    end

    it "returns the expected data when there is no related assessment" do
      result = gateway.fetch("0000-0000-0000-0000-0000")
      expect(result["count_address_id_assessments"]).to eq(1)
    end

    it "returns the expected data when there is a related assessment" do
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
      result = gateway.fetch("0000-0000-0000-0000-0002")
      expect(result["count_address_id_assessments"]).to eq(2)
    end
  end
end
