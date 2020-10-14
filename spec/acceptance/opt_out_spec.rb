describe "Acceptance::OptOut" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  context "when opting out an assessment" do
    it "removes them from the certificate search" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA", [200]).body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 1

      opt_out_assessment("0000-0000-0000-0000-0000")

      response =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA", [200]).body,
          symbolize_names: true,
        )

      expect(response[:data][:assessments].length).to eq 0
    end
  end

  context "when opting out an assessment that doesnt exist" do
    it "returns 404" do
      opt_out_assessment("0000-0000-0000-0000-0000", [404])
    end
  end
end
