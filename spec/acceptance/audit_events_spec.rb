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

  it "saves the decoded auth token from the request headers as JSON" do
    expect(JSON.parse(saved_data.first["data"])["auth_token"]["payload"]).to match a_hash_including(
      { "iss" => "test.issuer",
        "scopes" => ["assessment:lodge"],
        "sub" => "test-subject",
        "sup" => { "scheme_ids" => [scheme_id] } },
    )
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
          "event_type" => "opt_out" },
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
          "event_type" => "opt_in" },
      )
    end
  end

  context "when cancelling an assessment" do
    before do
      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          status: "CANCELLED",
        },
        auth_data: {
          scheme_ids: [scheme_id],
        },
        accepted_responses: [200],
      )
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "cancelled" },
      )
    end
  end

  context "when marking an assessment not for issue" do
    before do
      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          status: "NOT_FOR_ISSUE",
        },
        auth_data: {
          scheme_ids: [scheme_id],
        },
        accepted_responses: [200],
      )
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "cancelled" },
      )
    end
  end
end
