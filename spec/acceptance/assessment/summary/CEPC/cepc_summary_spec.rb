# frozen_string_literal: true

describe "Acceptance::AssessmentSummary::CEPC" do
  include RSpecRegisterApiServiceMixin

  context "when a valid CEPC 8.0.0 is lodged" do
    let(:response) {
      scheme_id = add_scheme_and_get_id
      assessor = AssessorStub.new.fetch_request_body(nonDomesticNos3: "ACTIVE", nonDomesticNos4: "ACTIVE", nonDomesticNos5: "ACTIVE")
      add_assessor(scheme_id, "SPEC000000", assessor)
      xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
      lodge_assessment(
          assessment_body: xml_file,
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
          )

      JSON.parse(fetch_assessment_summary("0000-0000-0000-0000-0000").body, symbolize_names: true)
    }

    it "Returns the assessment id" do
      expect(response[:data][:assessmentId]).to eq("0000-0000-0000-0000-0000")
    end
  end
end
