describe "Audit events" do
  include RSpecRegisterApiServiceMixin

  before do
    EventBroadcaster.enable!

    add_super_assessor(scheme_id: scheme_id)
    lodge_assessment(
      assessment_body: Samples.xml("RdSAP-Schema-20.0.0"),
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
    )
  end

  let(:scheme_id) { add_scheme_and_get_id }

  let(:saved_data) do
    ActiveRecord::Base.connection.exec_query("SELECT * FROM audit_logs ORDER BY timestamp DESC")
  end

  it "saves the request headers as JSON" do
    expect(JSON.parse(saved_data.first["data"])).to match a_hash_including(
      { "REQUEST_METHOD" => "POST",
        "SERVER_NAME" => "example.org",
        "QUERY_STRING" => "",
        "PATH_INFO" => "/api/assessments",
        "CONTENT_LENGTH" => "16479",
        "REMOTE_ADDR" => "127.0.0.1",
        "CONTENT_TYPE" => "application/xml+RdSAP-Schema-20.0.0" },
    )
    expect(JSON.parse(saved_data.first["data"])).to have_key("HTTP_AUTHORIZATION")
  end

  context "when lodging an assessment" do
    it "saves the event to the audit log" do
      expect(saved_data).to match [a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "lodgement" },
      )]
    end
  end

  context "when opting out an assessment" do
    before do
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "opt out" },
      )
    end
  end

  context "when opting in an assessment" do
    before do
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000", opt_out: false)
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "opt in" },
      )
    end
  end
end
