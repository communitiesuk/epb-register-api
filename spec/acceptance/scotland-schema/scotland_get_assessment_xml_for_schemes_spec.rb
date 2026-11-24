describe "Acceptance::ScotlandGetAssessment", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }
  let(:scheme_id_2) { add_scheme_and_get_id(name: "bad scheme") }

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

  context "when a scheme requests xml for a Scottish assessment it has lodged" do
    it "returns the xml" do
      response = fetch_scottish_assessment(
        auth_data: { 'scheme_ids': [scheme_id] },
        assessment_id: "0000-0000-0000-0000-0000",
        headers: {
          "Accept": "application/xml",
        },
      )

      expect(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{response.body}",
      ).to eq(expected_response)
    end
  end

  it_behaves_like "when checking an endpoint requires bearer token access", end_point: "scotland/assessments/some-id", scopes: %w[scotland_assessment:fetch]

  describe "error scenarios" do
    it "raises an error if a scheme that didn't lodge the assessment requests it" do
      response = fetch_scottish_assessment(
        auth_data: { 'scheme_ids': [scheme_id_2] },
        assessment_id: "0000-0000-0000-0000-0000",
        headers: {
          "Accept": "application/xml",
        },
        accepted_responses: [403],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "You are not authorised to view this scheme's lodged data"
    end

    it "raises an error if you request an assessment that has been cancelled" do
      ActiveRecord::Base.connection.exec_query("UPDATE scotland.assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")

      response = fetch_scottish_assessment(
        auth_data: { 'scheme_ids': [scheme_id] },
        assessment_id: "0000-0000-0000-0000-0000",
        headers: {
          "Accept": "application/xml",
        },
        accepted_responses: [410],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Assessment not for issue"
    end

    it "raises an error if the assessment you have requested doesn't exist" do
      response = fetch_scottish_assessment(
        auth_data: { 'scheme_ids': [scheme_id] },
        assessment_id: "0000-0000-0000-0000-0009",
        headers: {
          "Accept": "application/xml",
        },
        accepted_responses: [404],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Assessment not found"
    end

    it "raises an error if you provide it with something other than an assessment id" do
      response = fetch_scottish_assessment(
        auth_data: { 'scheme_ids': [scheme_id] },
        assessment_id: "bad-example",
        headers: {
          "Accept": "application/xml",
        },
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "The requested assessment id is not valid"
    end
  end
end
