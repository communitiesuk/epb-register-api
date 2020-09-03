describe "Acceptance::DECSummary" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id,
      "SPEC000000",
      fetch_assessor_stub.fetch_request_body(
        nonDomesticDec: "ACTIVE", nonDomesticNos3: "ACTIVE",
      ),
    )

    scheme_id
  end

  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }

  context "an assessment that is not a DEC" do
    it "returns error 403, assessment is not a DEC" do
      lodge_assessment(
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [403]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment is not a DEC")
    end
  end

  context "when assessment id is malformed" do
    it "returns error 400, assessment id is not valid" do
      response =
        JSON.parse(
          fetch_dec_summary("malformed-rrn", [400]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq(
        "The requested assessment id is not valid",
      )
    end
  end

  context "when an assessment doesn't exist" do
    it "returns error 404, assessment not found" do
      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [404]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment not found")
    end
  end

  context "when assessment has been cancelled" do
    it "returns error 410, assessment not for issue" do
      lodge_assessment(
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      JSON.parse(
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: { "status": "CANCELLED" },
          accepted_responses: [200],
          auth_data: { scheme_ids: [scheme_id] },
        ).body,
        symbolize_names: true,
      )

      response =
        JSON.parse(
          fetch_dec_summary("0000-0000-0000-0000-0000", [410]).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq("Assessment not for issue")
    end
  end
end
