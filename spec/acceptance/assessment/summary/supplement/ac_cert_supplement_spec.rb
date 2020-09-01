describe "Acceptance::AssessmentSummary::Supplement::AC_CERT" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor =
      AssessorStub.new.fetch_request_body(
        nonDomesticSp3: "ACTIVE", nonDomesticCc4: "ACTIVE",
      )
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_ac_cert(Samples.xml("CEPC-8.0.0", "ac-cert+ac-report"), scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )
  end

  context "when getting the related party disclosure" do
    it "returns the value lodged in the related document" do
      disclosure = @regular_summary.dig(:data, :relatedPartyDisclosure)
      expect(disclosure).to eq("1")
    end
  end
end

def lodge_ac_cert(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "CEPC-8.0.0",
  )
end
