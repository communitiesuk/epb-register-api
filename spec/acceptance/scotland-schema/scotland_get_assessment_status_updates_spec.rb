describe "Acceptance::ScotlandGetAssessmentStatusUpdates", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  let(:events_date) { Date.today - 1.week }

  let(:valid_scottish_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }

  before do
    Events::Broadcaster.enable!

    add_super_assessor(scheme_id:)
    lodge_assessment(assessment_body: valid_scottish_rdsap_xml,
                     accepted_responses: [201],
                     scopes: %w[migrate:scotland],
                     auth_data: {
                       scheme_ids: [scheme_id],
                     },
                     schema_name: "RdSAP-Schema-S-19.0",
                     migrated: true)
    opt_out_scottish_assessment(
      assessment_id: "0000-0000-0000-0000-0000",
      opt_out: true,
    )
    opt_out_scottish_assessment(
      assessment_id: "0000-0000-0000-0000-0000",
      opt_out: false,
    )
    update_scottish_assessment_status(assessment_id: "0000-0000-0000-0000-0000",
                                      assessment_status_body: {
                                        status: "CANCELLED",
                                      },
                                      accepted_responses: [200],
                                      auth_data: { scheme_ids: [scheme_id] })
    ActiveRecord::Base.connection.exec_query("UPDATE audit_logs SET timestamp = '#{events_date}' WHERE entity_id = '0000-0000-0000-0000-0000' ")
  end

  after do
    Events::Broadcaster.disable!
  end

  def expected_response
    JSON.parse({ data: {
                   statusUpdates: [
                     {
                       reportRrn: "0000-0000-0000-0000-0000",
                       newStatus: "OPTED OUT",
                       timeOfChange: events_date,
                     },
                     {
                       reportRrn: "0000-0000-0000-0000-0000",
                       newStatus: "OPTED IN",
                       timeOfChange: events_date,
                     },
                     {
                       reportRrn: "0000-0000-0000-0000-0000",
                       newStatus: "CANCELLED",
                       timeOfChange: events_date,
                     },
                   ],
                 },
                 meta: { nextPage: nil,
                         currentPage: "http://example.org/api/scotland/v1/updates/assessments/status?startDate=2021-05-31&endDate=2021-06-15&page=1",
                         previousPage: nil } }.to_json)
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      expect(scottish_get_assessment_status_updates(
        start_date: "2020-01-01",
        end_date: "2020-01-02",
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq(401)
    end

    it "rejects a request without the right scope" do
      expect(scottish_get_assessment_status_updates(
        start_date: "2020-01-01",
        end_date: "2020-01-02",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq(403)
    end
  end

  context "when requesting a list of status updates between two dates" do
    it "returns the data and details about pagination" do
      response = scottish_get_assessment_status_updates(
        start_date: events_date - 2.week,
        end_date: events_date + 1.day,
        page: 1,
      )

      response_json = JSON.parse(response.body)

      expect(response_json.keys).to contain_exactly("data", "meta")
      expect(response_json["data"]["statusUpdates"].first.keys).to contain_exactly("newStatus", "reportRrn", "timeOfChange")
      expect(response_json["data"]["statusUpdates"].map { |update| update["newStatus"] }).to contain_exactly("CANCELLED", "OPTED OUT", "OPTED IN")

      expect(response_json["meta"]).to eq(expected_response["meta"])
    end

    it "defaults to page 1 if you don't specify a page" do
      response = scottish_get_assessment_status_updates(
        start_date: events_date - 2.week,
        end_date: events_date + 1.day,
      )

      response_json = JSON.parse(response.body)

      expect(response_json["meta"]).to eq(JSON.parse(
                                                  { nextPage: nil,
                                                    currentPage: "http://example.org/api/scotland/v1/updates/assessments/status?startDate=2021-05-31&endDate=2021-06-15",
                                                    previousPage: nil }.to_json,
                                                ))
    end
  end

  describe "error scenarios" do
    it "raises an error if you provide a date in the wrong format" do
      response = scottish_get_assessment_status_updates(
        start_date: "2021-06-01",
        end_date: "not a date",
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "JSON failed schema validation. Error: The property '#/endDate' Must be date in format YYYY-MM-DD"
    end

    it "raises an error if you request a page out of range" do
      response = scottish_get_assessment_status_updates(
        start_date: events_date - 2.week,
        end_date: events_date + 1.day,
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "The requested page number 2 is out of range. There are 1 pages."
    end

    it "raises an error if you make a request with a date range that returns no data" do
      response = scottish_get_assessment_status_updates(
        start_date: "2010-06-20",
        end_date: "2010-06-22",
        page: 2,
        accepted_responses: [404],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Date range did not return any data"
    end

    it "raises an error if you make a request a date range including today" do
      response = scottish_get_assessment_status_updates(
        start_date: "2010-06-20",
        end_date: Date.today.to_s,
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "A required argument is is invalid: date range includes today"
    end

    it "raises an error if you make a request with the date range reversed" do
      response = scottish_get_assessment_status_updates(
        start_date: events_date + 1.day,
        end_date: events_date - 2.week,
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "A required argument is is invalid: date_from cannot be greater than date_to"
    end
  end
end
