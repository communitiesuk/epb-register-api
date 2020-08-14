describe "Acceptance::AssessmentStatus::AC-REPORT" do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_acir_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/ac-report.xml"
  end

  context "when marking an AC-REPORT assessment not for issue" do
    let(:response) do
      scheme_id = add_scheme_and_get_id

      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(
          nonDomesticCc4: "ACTIVE", nonDomesticSp3: "ACTIVE",
        ),
      )

      lodge_assessment assessment_body: valid_acir_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "CEPC-8.0.0"

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
