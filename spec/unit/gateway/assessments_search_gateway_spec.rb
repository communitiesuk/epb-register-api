describe Gateway::AssessmentsSearchGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  before do
    add_super_assessor(scheme_id:)
    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
    )
  end

  describe ".search_by_postcode" do
    it "returns the expected data" do
      result = gateway.search_by_postcode("A0 0AA")

      expect(result.count).to eq(1)
      expect(result.first).to be_a(Domain::AssessmentSearchResult)
    end
  end

  describe ".search_by_street_name_and_town" do
    before do
      domestic_rdsap_xml_2 = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      domestic_rdsap_xml_2.at("RRN").content = "0000-0000-0000-0000-0001"
      domestic_rdsap_xml_2.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "2 Some Street" }
      lodge_assessment(
        assessment_body: domestic_rdsap_xml_2.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end

    it "returns the expected data" do
      result = gateway.search_by_street_name_and_town("Some Street", "Whitbury", %w[RdSAP])
      expect(result.count).to eq(2)
      expect(result.first).to be_a(Domain::AssessmentSearchResult)
    end
  end
end
