describe Gateway::AssessmentsSearchGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  before do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id: scheme_id)

    domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    lodge_assessment(
      assessment_body: domestic_rdsap_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )
  end

  describe ".search_by_postcode" do
    it "returns the expected data" do
      result = gateway.search_by_postcode("A0 0AA")

      expect(result.count).to eq(1)
      expect(result.first).to be_a(Domain::AssessmentSearchResult)
    end
  end
end
