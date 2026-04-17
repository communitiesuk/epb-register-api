describe "Acceptance::ScotlandGetAssessorStatusUpdates", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:events_date) { Date.today - 1.week }

  before do
    scheme_id = add_scheme_and_get_id

    # create new assessor
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body,
    )

    # change that assessors scottish qualification from inactive to active to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE"),
    )

    # change that assessors non-scottish qualification from inactive to active to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE", domestic_rd_sap: "ACTIVE"),
    )

    # change that assessors scottish qualification from active to struckoff to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "STRUCKOFF", domestic_rd_sap: "ACTIVE"),
    )

    # change that assessors scottish qualification from struckoff to suspended to generate an event
    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "SUSPENDED", domestic_rd_sap: "ACTIVE"),
    )

    ActiveRecord::Base.connection.exec_query("UPDATE assessors_status_events SET recorded_at = '#{events_date}' ")
  end

  def expected_response
    JSON.parse({ data: {
                   assessorStatusUpdates: [
                     {
                       dateOfBirth: "1991-02-25",
                       firstName: "Someone",
                       lastName: "Person",
                       middleNames: nil,
                       qualificationChange: {
                         newStatus: "ACTIVE",
                         previousStatus: "INACTIVE",
                         qualificationType: "scotland_rdsap",
                       },
                       schemeAssessorId: "ACME123456",
                     },
                     {
                       dateOfBirth: "1991-02-25",
                       firstName: "Someone",
                       lastName: "Person",
                       middleNames: nil,
                       qualificationChange:
                         { newStatus: "STRUCKOFF",
                           previousStatus: "ACTIVE",
                           qualificationType: "scotland_rdsap" },
                       schemeAssessorId: "ACME123456",
                     },
                     { dateOfBirth: "1991-02-25",
                       firstName: "Someone",
                       lastName: "Person",
                       middleNames: nil,
                       qualificationChange:
                        { newStatus: "SUSPENDED",
                          previousStatus: "STRUCKOFF",
                          qualificationType: "scotland_rdsap" },
                       schemeAssessorId: "ACME123456" },
                   ],
                 },
                 links: { next: nil,
                          self: "http://example.org/api/scotland/v1/updates/assessors/status?startDate=2021-06-13&endDate=2021-06-15&page=1",
                          prev: nil },
                 meta: {} }.to_json)
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      expect(scottish_get_assessors_status_updates(
        start_date: "2020-01-01",
        end_date: "2020-01-02",
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq(401)
    end

    it "rejects a request without the right scope" do
      expect(scottish_get_assessors_status_updates(
        start_date: "2020-01-01",
        end_date: "2020-01-02",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq(403)
    end
  end

  context "when requesting a list of assessor status updates between two dates" do
    it "returns the data and details about pagination" do
      response = scottish_get_assessors_status_updates(
        start_date: events_date - 1.day,
        end_date: events_date + 1.day,
        page: 1,
      )

      response_json = JSON.parse(response.body)

      expect(response_json).to eq(expected_response)
    end

    it "defaults to page 1 if you don't specify a page" do
      response = scottish_get_assessors_status_updates(
        start_date: events_date - 1.day,
        end_date: events_date + 1.day,
      )

      response_json = JSON.parse(response.body)

      expect(response_json["links"]).to eq(JSON.parse(
                                             { next: nil,
                                               self: "http://example.org/api/scotland/v1/updates/assessors/status?startDate=2021-06-13&endDate=2021-06-15",
                                               prev: nil }.to_json,
                                           ))
    end
  end

  describe "error scenarios" do
    it "raises an error if you provide a date in the wrong format" do
      response = scottish_get_assessors_status_updates(
        start_date: "2021-06-01",
        end_date: "not a date",
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "JSON failed schema validation. Error: The property '#/endDate' Must be date in format YYYY-MM-DD"
    end

    it "raises an error if you request a page out of range" do
      response = scottish_get_assessors_status_updates(
        start_date: events_date - 2.week,
        end_date: events_date + 1.day,
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "The requested page number 2 is out of range. There are 1 pages."
    end

    it "raises an error if you make a request with a date range that returns no data" do
      response = scottish_get_assessors_status_updates(
        start_date: "2010-06-20",
        end_date: "2010-06-22",
        page: 2,
        accepted_responses: [404],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "Date range did not return any data"
    end

    it "raises an error if you make a request a date range including today" do
      response = scottish_get_assessors_status_updates(
        start_date: "2010-06-20",
        end_date: Date.today.to_s,
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "A required argument is is invalid: date range includes today"
    end

    it "raises an error if you make a request with the date range reversed" do
      response = scottish_get_assessors_status_updates(
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
