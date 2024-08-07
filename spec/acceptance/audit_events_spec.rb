describe "Audit events", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before do
    Events::Broadcaster.enable!

    add_super_assessor(scheme_id:)
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

  context "when adding a new assessor" do
    it "saves addingthe assessor the event to the audit log" do
      expect(saved_data.first).to match a_hash_including(
        { "entity_type" => "assessor",
          "entity_id" => "SPEC000000",
          "event_type" => "added" },
      )
    end

    it "saves the decoded auth token from the request headers as JSON" do
      expect(JSON.parse(saved_data.first["data"])["auth_token"]["payload"]).to match a_hash_including(
        { "iss" => "test.issuer",
          "scopes" => ["scheme:assessor:update"],
          "sub" => "test-subject",
          "sup" => { "scheme_ids" => [scheme_id] } },
      )
    end
  end

  context "when lodging an assessment" do
    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "lodgement" },
      )
    end

    it "saves the decoded auth token from the request headers as JSON" do
      expect(JSON.parse(saved_data.last["data"])["auth_token"]["payload"]).to match a_hash_including(
        { "iss" => "test.issuer",
          "scopes" => include("assessment:lodge"),
          "sub" => "test-subject",
          "sup" => { "scheme_ids" => [scheme_id] } },
      )
    end

    context "when writing audit log to the database fails" do
      failing_assessment_rrn = "0000-0000-0000-0000-0001"
      second_assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
      second_assessment.at("RRN").children = failing_assessment_rrn

      scheme_id = nil

      before do
        ApiFactory.clear!

        # we need to use break out of any transaction started by DatabaseCleaner
        DatabaseCleaner.clean

        # adding this assessor, and scheme, was nixed by transaction rollback
        scheme_id = add_scheme_and_get_id
        add_super_assessor(scheme_id:)

        ActiveRecord::Base.connection.exec_query("ALTER TABLE audit_logs RENAME TO audit_logs_obscured")

        # silence logging in this test
        allow($stdout).to receive(:write)
      end

      it "does not write the assessment and returns a 500" do
        lodge_assessment(
          assessment_body: second_assessment.to_xml,
          accepted_responses: [500],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        )

        ActiveRecord::Base.connection.reconnect!
        is_assessment_written = !ActiveRecord::Base.connection.exec_query("SELECT * FROM assessments WHERE assessment_id = '#{failing_assessment_rrn}'").rows.empty?
        expect(is_assessment_written).to be false
      end
    end
  end

  context "when opting out an assessment" do
    before do
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
    end

    it "saves the event to the audit log" do
      expect(saved_data.find { |event| event["event_type"] == "opt_out" }).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000" },
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

  context "when updating assessment's address id" do
    before do
      add_address_base(uprn: 73_546_793)
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "assessment",
          "entity_id" => "0000-0000-0000-0000-0000",
          "event_type" => "address_id_updated" },
      )
    end
  end

  context "when a green deal plan is added" do
    before do
      load_green_deal_data
      add_green_deal_plan(assessment_id: "0000-0000-0000-0000-0000",
                          body: GreenDealPlanStub.new.request_body)
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "green_deal_plan",
          "entity_id" => "ABC123456DEF",
          "event_type" => "green_deal_plan_added",
          "data" => json_contains_hash(assessment_id: "0000-0000-0000-0000-0000") },
      )
    end
  end

  context "when a green deal plan is updated" do
    let(:updated_green_deal_plan_request_body) do
      {
        greenDealPlanId: "ABC123456DEF",
        startDate: "2020-02-28",
        endDate: "2030-03-30",
        providerDetails: {
          name: "The New Bank",
          telephone: "0900 0000000",
          email: "lender@example.io",
        },
        interest: {
          rate: 12.5,
          fixed: false,
        },
        chargeUplift: {
          amount: 0.25,
          date: "2025-04-29",
        },
        ccaRegulated: false,
        structureChanged: true,
        measuresRemoved: true,
        measures: [
          {
            sequence: 0,
            measureType: "Cavity Wall",
            product: "ColdHome lagging stuff (TM)",
            repaidDate: "2025-04-29",
          },
        ],
        charges: [
          {
            sequence: 0,
            startDate: "2020-04-29",
            endDate: "2030-04-29",
            dailyCharge: 0.35,
          },
        ],
        savings: [
          { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
          { fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9 },
          { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
        ],
      }
    end

    before do
      load_green_deal_data
      add_green_deal_plan(assessment_id: "0000-0000-0000-0000-0000",
                          body: GreenDealPlanStub.new.request_body)
      update_green_deal_plan(
        plan_id: "ABC123456DEF",
        body: updated_green_deal_plan_request_body,
      )
    end

    it "saves the event to the audit log under a green deal plan" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "green_deal_plan",
          "entity_id" => "ABC123456DEF",
          "event_type" => "green_deal_plan_updated",
          "data" => json_contains_hash(assessment_ids: %w[0000-0000-0000-0000-0000]) },
      )
    end
  end

  context "when a green deal plan is deleted" do
    before do
      load_green_deal_data
      add_green_deal_plan(assessment_id: "0000-0000-0000-0000-0000",
                          body: GreenDealPlanStub.new.request_body)
      delete_green_deal_plan(plan_id: "ABC123456DEF")
    end

    it "saves the event to the audit log" do
      expect(saved_data.last).to match a_hash_including(
        { "entity_type" => "green_deal_plan",
          "entity_id" => "ABC123456DEF",
          "event_type" => "green_deal_plan_deleted",
          "data" => json_contains_hash(assessment_ids: %w[0000-0000-0000-0000-0000]) },
      )
    end
  end
end
