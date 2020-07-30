# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::CEPC_8.0.0" do
  include RSpecRegisterApiServiceMixin

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end

  context "A full CEPC 8.0.0 document is lodged" do
    let(:scheme_id) { add_scheme_and_get_id }

    before do
      add_assessor(scheme_id, "SPEC000000", VALID_ASSESSOR_REQUEST_BODY)
      doc = Nokogiri.XML valid_cepc_xml

      lodge_assessment(
        assessment_body: doc.to_xml,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end

    let(:response) do
      JSON.parse(fetch_assessment_summary("0000-0000-0000-0000-0000").body)
    end

    it "Returns the assessment ID" do
      expect(response["data"]["assessmentId"]).to eq("0000-0000-0000-0000-0000")
    end
  end
end
