describe "Acceptance::ScotlandGetAssessmentXml", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  let(:valid_scottish_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }

  before do
    add_super_assessor(scheme_id:)
    lodge_scottish_assessment(assessment_body: valid_scottish_rdsap_xml,
                              accepted_responses: [201],
                              scopes: %w[migrate:scotland],
                              auth_data: {
                                scheme_ids: [scheme_id],
                              },
                              schema_name: "RdSAP-Schema-S-19.0",
                              migrated: true)
  end

  def expected_response
    valid_scottish_rdsap_xml
  end

  context "when requesting xml for an assessment" do
    it "returns the xml" do
      response = scottish_get_assessment_xml(
        assessment_id: "0000-0000-0000-0000-0000",
        auth_data: { 'scheme_ids': [scheme_id] },
      )

      expect(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{response.body}",
      ).to eq(expected_response)
    end
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      expect(scottish_get_assessment_xml(
        assessment_id: "0000-0000-0000-0000-0000",
        auth_data: { 'scheme_ids': [scheme_id] },
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq(401)
    end

    it "rejects a request without the right scope" do
      response = scottish_get_assessment_xml(
        assessment_id: "0000-0000-0000-0000-0000",
        auth_data: { 'scheme_ids': [scheme_id] },
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "You are not authorised to perform this request"
    end

    it "rejects a request when the provided auth schemes do not match the scheme id from the assessment" do
      response = scottish_get_assessment_xml(
        assessment_id: "0000-0000-0000-0000-0000",
        auth_data: { 'scheme_ids': %w[1] },
        accepted_responses: [403],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "You are not authorised to view this scheme's lodged data"
    end
  end

  describe "error scenarios" do
    it "raises an error if the assessment you have requested doesn't exist" do
      response = scottish_get_assessment_xml(
        assessment_id: "0000-0000-0000-0000-0009",
        auth_data: { 'scheme_ids': [scheme_id] },
        accepted_responses: [404],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Assessment ID did not return any data"
    end

    it "raises an error if you provide it with something other than an assessment id" do
      response = scottish_get_assessment_xml(
        assessment_id: "bad-example",
        auth_data: { 'scheme_ids': [scheme_id] },
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "The requested assessment id is not valid"
    end
  end
end
