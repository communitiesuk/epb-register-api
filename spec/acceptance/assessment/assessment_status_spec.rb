describe "Acceptance::AssessmentStatus", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id: scheme_id,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(domestic_rd_sap: "ACTIVE"),
    )

    scheme_id
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  context "when assessment does not exist" do
    it "responds with 404 not found when cancelling an assessment" do
      response = update_assessment_status(assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            status: "CANCELLED",
                                          },
                                          accepted_responses: [404],
                                          auth_data: { scheme_ids: [scheme_id] })

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "NOT_FOUND", title: "Assessment not found" }],
      )
    end

    it "responds with 404 not found when marking the assessment as not for issue" do
      response = update_assessment_status(assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            status: "NOT_FOR_ISSUE",
                                          },
                                          accepted_responses: [404],
                                          auth_data: { scheme_ids: [scheme_id] })

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "NOT_FOUND", title: "Assessment not found" }],
      )
    end
  end

  context "when assessment exists" do
    before do
      lodge_assessment(assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] })
    end

    it "responds that the assessment has already been cancelled for a previously cancelled assessment" do
      update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                               assessment_status_body: {
                                 "status": "CANCELLED",
                               },
                               accepted_responses: [200],
                               auth_data: { scheme_ids: [scheme_id] }

      response = update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            status: "CANCELLED",
                                          },
                                          accepted_responses: [410],
                                          auth_data: { scheme_ids: [scheme_id] }

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "GONE", title: "Assessment has already been cancelled" }],
      )
    end

    it "responds that the assessment has already been cancelled for a previously marked 'not for issue' assessment" do
      update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                               assessment_status_body: {
                                 "status": "NOT_FOR_ISSUE",
                               },
                               accepted_responses: [200],
                               auth_data: { scheme_ids: [scheme_id] }

      response = update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            status: "NOT_FOR_ISSUE",
                                          },
                                          accepted_responses: [410],
                                          auth_data: { scheme_ids: [scheme_id] }

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "GONE", title: "Assessment has already been cancelled" }],
      )
    end

    it "rejects a request when the assessment doesn't belong to the scheme" do
      response = update_assessment_status(assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            "status": "NOT_FOR_ISSUE",
                                          },
                                          accepted_responses: [403],
                                          auth_data: { scheme_ids: [scheme_id + 1] })

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "NOT_ALLOWED", title: "UseCase::UpdateAssessmentStatus::AssessmentNotLodgedByScheme" }],
      )
    end

    it "rejects a request that is not authenticated" do
      response = update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            status: "CANCELLED",
                                          },
                                          accepted_responses: [401],
                                          authenticate: false

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "Auth::Errors::TokenMissing" }],
      )
    end

    it "rejects a request with the wrong authorisation scopes" do
      response = update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                                          assessment_status_body: {
                                            status: "CANCELLED",
                                          },
                                          accepted_responses: [403],
                                          scopes: %w[wrong:scope]

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "UNAUTHORISED", title: "You are not authorised to perform this request" }],
      )
    end

    it "rejects a request with invalid request body" do
      response = assertive_post(
        "/api/assessments/0000-0000-0000-0000-0000/status",
        body: { invalid_status_key: "CANCELLED" },
        accepted_responses: [422],
        scopes: %w[assessment:lodge],
      )

      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "INVALID_REQUEST", title: "The property '#/' did not contain a required property of 'status'" }],
      )
    end
  end
end
