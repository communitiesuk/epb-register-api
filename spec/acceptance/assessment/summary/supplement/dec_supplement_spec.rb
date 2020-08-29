describe "Acceptance::AssessmentSummary::Supplement::RdSAP" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(nonDomesticDec: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_dec(Samples.xml("CEPC-8.0.0", "dec"), scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )

    second_assessment = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec"))
    second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
    lodge_dec(second_assessment.to_xml, scheme_id)
    @second_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )
  end

  context "when getting the scheme data supplement" do
    it "Adds scheme details" do
      scheme = @regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end
  end
end

def lodge_dec(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "CEPC-8.0.0",
  )
end
