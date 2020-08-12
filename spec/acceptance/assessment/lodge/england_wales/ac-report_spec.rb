# frozen_string_literal: true

describe "Acceptance::LodgeAC-REPORTEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/ac-report.xml"
  end

  context "when lodging AC-REPORT" do
    context "with an active assessor" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticSp3: "ACTIVE"),
        )

        lodge_assessment(
          assessment_body: valid_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "accepts an assessment with type AC-REPORT" do
        expect(response["data"]["typeOfAssessment"]).to eq("AC-REPORT")
      end
    end
  end

  context "when rejecting an assessment" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:doc) { Nokogiri.XML valid_xml }

    before do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticSp3: "ACTIVE"),
      )

      doc.at("ACI-Related-Party-Disclosure").remove
    end

    it "rejects an assessment without an ACI Related-Party-Disclosure" do
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end
  end
end
