# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::Supplement::RdSAP" do
  include RSpecRegisterApiServiceMixin

  context "when getting the summary" do
    let(:rdsap) { Samples.xml "RdSAP-Schema-20.0.0" }
    let(:scheme_id) { add_scheme_and_get_id }
    let(:summary) do
      assessor = AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")
      add_assessor(scheme_id, "SPEC000000", assessor)

      lodge_assessment(
        assessment_body: rdsap,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "RdSAP-Schema-20.0.0",
      )

      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    end

    context "and getting the assessor data" do
      it "Adds scheme details" do
        scheme = summary.dig(:data, :assessor, :registeredBy)
        expect(scheme).to eq({ name: "test scheme", schemeId: scheme_id })
      end

      it "Returns lodged email and phone values by default" do
        contact_details = summary.dig(:data, :assessor, :contactDetails)
        expect(contact_details).to eq(
          { telephoneNumber: "0921-19037", email: "a@b.c" },
        )
      end
    end
  end
end
