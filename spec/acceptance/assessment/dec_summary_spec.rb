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
end
