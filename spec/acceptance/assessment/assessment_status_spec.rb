describe "Acceptance::AssessmentStatus" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end

  context "when cancelling an assessment" do
    it "then receives a response with of the cancelled status" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticRdSap: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      assessment_status =
        JSON.parse(
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: { "status": "CANCELLED" },
            accepted_responses: [200],
            auth_data: { scheme_ids: [scheme_id] },
          )
            .body,
          symbolize_names: true,
        )

      expect(assessment_status[:data][:status]).to eq("CANCELLED")
    end

    it "then updates the database accordingly" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticRdSap: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: { "status": "CANCELLED" },
        accepted_responses: [200],
        auth_data: { scheme_ids: [scheme_id] },
      )

      assessment = fetch_assessment("0000-0000-0000-0000-0000")
    end
  end

  context "when making an assessment not for issue" do
    it "then receives a response with of the not for issue status" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticRdSap: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      assessment_status =
        JSON.parse(
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: { "status": "NOT_FOR_ISSUE" },
            accepted_responses: [200],
            auth_data: { scheme_ids: [scheme_id] },
          )
            .body,
          symbolize_names: true,
        )

      expect(assessment_status[:data][:status]).to eq("NOT_FOR_ISSUE")
    end
  end
end
