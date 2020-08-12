# frozen_string_literal: true

describe "Acceptance::LodgeDEC(AR)NIEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/dec-rr-ni.xml"
  end

  context "when lodging DEC advisory reports NI" do
    let(:response) do
      JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
    end

    it "accepts an assessment with type DEC-RR" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-NI-8.0.0",
      )

      expect(response["data"]["typeOfAssessment"]).to eq("DEC-RR")
    end
  end

  context "when rejecting an assessment" do
    it "rejects an assessment without a technical information" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticDec: "ACTIVE"),
      )

      doc = Nokogiri.XML valid_xml

      scheme_assessor_id = doc.at("Technical-Information")
      scheme_assessor_id.children = ""

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        schema_name: "CEPC-NI-8.0.0",
      )
    end
  end
end
