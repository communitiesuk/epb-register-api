describe "Acceptance::ScotlandGetNewReports", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  def setup_scheme_and_lodge
    Timecop.freeze(Time.utc(2021, 6, 2))
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: AssessorStub.new.fetch_request_body(
        domestic_rd_sap: "ACTIVE",
        non_domestic_nos3: "ACTIVE",
      ),
    )
    lodge_scottish_assessment(
      assessment_body: Samples.xml("RdSAP-Schema-S-19.0"),
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "RdSAP-Schema-S-19.0",
      migrated: true,
    )
  end

  def expected_response
    JSON.parse({ data: {
                   rrns: %w[0000-0000-0000-0000-0000],
                 },
                 links: { prev: nil,
                          self: "http://example.org/api/scotland/v1/updates/new-reports?startDate=2021-06-01&endDate=2021-06-03&page=1",
                          next: nil },
                 meta: {} }.to_json)
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      expect(scottish_get_new_reports(
        start_date: "2020-01-01",
        end_date: "2020-01-02",
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq(401)
    end

    it "rejects a request without the right scope" do
      expect(scottish_get_new_reports(
        start_date: "2021-01-01",
        end_date: "2021-01-02",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq(403)
    end
  end

  context "when requesting a list of reports between two dates" do
    before do
      setup_scheme_and_lodge
      Timecop.freeze(Time.utc(2021, 7, 1))
    end

    after { Timecop.return }

    it "returns the data and details about pagination" do
      response = scottish_get_new_reports(
        start_date: "2021-06-01",
        end_date: "2021-06-03",
        page: 1,
      )

      response_json = JSON.parse(response.body)

      expect(response_json).to eq(expected_response)
    end

    it "defaults to page 1 if you don't specify a page" do
      response = scottish_get_new_reports(
        start_date: "2021-06-01",
        end_date: "2021-06-03",
      )

      response_json = JSON.parse(response.body)

      expect(response_json["links"]).to eq(JSON.parse(
                                             { prev: nil,
                                               self: "http://example.org/api/scotland/v1/updates/new-reports?startDate=2021-06-01&endDate=2021-06-03",
                                               next: nil }.to_json,
                                           ))
    end

    it "returns an empty list if there is no data" do
      response = scottish_get_new_reports(
        start_date: "2010-06-20",
        end_date: "2010-06-22",
      )

      response_json = JSON.parse(response.body)

      expect(response_json["data"]).to eq(JSON.parse(
                                            { rrns: [] }.to_json,
                                          ))
    end
  end

  describe "error scenarios" do
    before do
      setup_scheme_and_lodge
      Timecop.freeze(Time.utc(2021, 7, 1))
    end

    after { Timecop.return }

    it "raises an error if you provide a date in the wrong format" do
      response = scottish_get_new_reports(
        start_date: "2021-06-01",
        end_date: "not a date",
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "JSON failed schema validation. Error: The property '#/endDate' Must be date in format YYYY-MM-DD"
    end

    it "raises an error if you request a page out of range" do
      response = scottish_get_new_reports(
        start_date: "2021-06-01",
        end_date: "2021-06-03",
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "The requested page number 2 is out of range. There are 1 pages."
    end

    it "raises an error if you make a request a date range including today" do
      response = scottish_get_new_reports(
        start_date: "2010-06-20",
        end_date: Date.today.to_s,
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "A required argument is is invalid: date range includes today"
    end

    it "raises an error if you make a request with the date range reversed" do
      response = scottish_get_new_reports(
        start_date: "2021-06-03",
        end_date: "2021-06-01",
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "A required argument is is invalid: date_from cannot be greater than date_to"
    end
  end
end
