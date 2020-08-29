# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::Supplement::SAP" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(domesticSap: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_sap(Samples.xml("SAP-Schema-18.0.0"), scheme_id)
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = @regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end
  end
end

def lodge_sap(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "SAP-Schema-18.0.0",
  )
end
