describe "Acceptance::AssessmentStatus::SAP" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  context "when cancelling an SAP assessment" do
    let(:response) do
      scheme_id = add_scheme_and_get_id

      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-17.1"

      assessment_status =
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: { "status": "CANCELLED" },
          accepted_responses: [200],
          auth_data: { scheme_ids: [scheme_id] },
        )

      JSON.parse assessment_status.body, symbolize_names: true
    end

    it "cancels the assessment" do
      expect(response[:data][:status]).to eq("CANCELLED")
      fetch_assessment("0000-0000-0000-0000-0000", [410])
    end
  end

  context "when marking an SAP assessment not for issue" do
    let(:response) do
      scheme_id = add_scheme_and_get_id

      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-17.1"

      assessment_status =
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: { "status": "NOT_FOR_ISSUE" },
          accepted_responses: [200],
          auth_data: { scheme_ids: [scheme_id] },
        )

      JSON.parse assessment_status.body, symbolize_names: true
    end

    it "marks the assessment not for issue" do
      expect(response[:data][:status]).to eq("NOT_FOR_ISSUE")
      fetch_assessment("0000-0000-0000-0000-0000", [410])
    end
  end
end
