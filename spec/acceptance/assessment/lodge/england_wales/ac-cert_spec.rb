# frozen_string_literal: true

describe "Acceptance::LodgeAC-CERTEnergyAssessment" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_acic_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/ac-cert.xml"
  end

  context "when lodging an AC-CERT assessment (post)" do
    context "when an assessor is active" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
        )

        lodge_assessment(
          assessment_body: valid_cepc_acic_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "accepts an assessment with type AC-CERT" do
        expect(response["data"]["typeOfAssessment"]).to eq("AC-CERT")
      end
    end
  end

  context "when rejecting an assessment" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:doc) { Nokogiri.XML valid_cepc_acic_xml }

    before do
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(nonDomesticCc4: "ACTIVE"),
      )

      doc.at("AC-Rated-Output").remove
    end

    it "rejects an assessment without an AC Rated Output" do
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [400],
        schema_name: "CEPC-NI-8.0.0",
      )
    end
  end
end
