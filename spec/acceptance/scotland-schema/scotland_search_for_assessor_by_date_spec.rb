require_relative "../../shared_context/shared_scottish_assesors"

describe "Acceptance::ScotlandGetAssessorByDate", :set_with_timecop do
  include RSpecRegisterApiServiceMixin
  include_context "when testing Scottish assessors"


  let(:events_time) { Time.now.utc }
  let(:expected_response) do
    JSON.parse({ data: {
                   newAssessors: [
                     {
                       firstName: "Someone",
                       lastName: "Person",
                       schemeAssessorId: "ACME123456",
                       qualifications: {
                         domesticRdSap: "INACTIVE",
                         domesticSap: "INACTIVE",
                         nonDomesticDec: "INACTIVE",
                         nonDomesticNos3: "INACTIVE",
                         nonDomesticNos4: "INACTIVE",
                         nonDomesticNos5: "INACTIVE",
                         nonDomesticSp3: "INACTIVE",
                         nonDomesticCc4: "INACTIVE",
                         gda: "INACTIVE",
                         scotlandRdsap: "ACTIVE",
                         scotlandSapExistingBuilding: "INACTIVE",
                         scotlandSapNewBuilding: "INACTIVE",
                         scotlandDecAndAr: "INACTIVE",
                         scotlandNondomesticExistingBuilding: "INACTIVE",
                         scotlandNondomesticNewBuilding: "INACTIVE",
                         scotlandSection63: "INACTIVE",
                       },

                     },
                     {
                       firstName: "John",
                       lastName: "Smith",
                       schemeAssessorId: "ACME123457",
                       qualifications: {
                         domesticRdSap: "INACTIVE",
                         domesticSap: "INACTIVE",
                         nonDomesticDec: "INACTIVE",
                         nonDomesticNos3: "INACTIVE",
                         nonDomesticNos4: "INACTIVE",
                         nonDomesticNos5: "INACTIVE",
                         nonDomesticSp3: "INACTIVE",
                         nonDomesticCc4: "INACTIVE",
                         gda: "INACTIVE",
                         scotlandRdsap: "INACTIVE",
                         scotlandSapExistingBuilding: "INACTIVE",
                         scotlandSapNewBuilding: "INACTIVE",
                         scotlandDecAndAr: "INACTIVE",
                         scotlandNondomesticExistingBuilding: "ACTIVE",
                         scotlandNondomesticNewBuilding: "INACTIVE",
                         scotlandSection63: "INACTIVE",
                       },

                     },
                   ],
                 },
                 links: { next: nil,
                          self: "#{url}?startDate=#{start_date}&endDate=#{end_date}&page=1",
                          prev: nil },
                 meta: {} }.to_json)
  end
  let(:events_date) { Date.parse(events_time.to_s) }
  let(:start_date) { events_date - 2.days }
  let(:end_date) { events_date - 1.day }
  let(:url) { "http://example.org/api/scotland/v1/updates/new-assessors" }

  before do
    scheme_id = 999
    Gateway::SchemesGateway::Scheme.create(scheme_id:, name: "Scottish Scheme")

    add_assessor(
      scheme_id:,
      assessor_id: "ACME123456",
      body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE"),
    )

    add_assessor(
      scheme_id:,
      assessor_id: "ACME123457",
      body: AssessorStub.new.fetch_request_body(scotland_nondomestic_existing_building: "ACTIVE", first_name: "John", last_name: "Smith", email: "J@person.com"),
    )

    add_assessor(
      scheme_id:,
      assessor_id: "ACME123458",
      body: AssessorStub.new.fetch_request_body(domestic_rd_sap: "ACTIVE"),
    )

    add_assessors_to_logs

    ActiveRecord::Base.connection.exec_query("UPDATE audit_logs SET timestamp = '#{start_date}'")
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      expect(scottish_get_assessors_by_date(
        start_date: events_date - 1.day,
        end_date: events_date + 1.day,
        accepted_responses: [401],
        should_authenticate: false,
      ).status).to eq(401)
    end

    it "rejects a request without the right scope" do
      expect(scottish_get_assessors_by_date(
        start_date: events_date - 1.day,
        end_date: events_date + 1.day,
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq(403)
    end
  end

  context "when requesting a list of assessors between two dates" do
    it "returns the data and details about pagination" do
      response = scottish_get_assessors_by_date(
        start_date:,
        end_date:,
        page: 1,
      )

      response_json = JSON.parse(response.body)
      expect(response_json).to eq(expected_response)
    end

    it "defaults to page 1 if you don't specify a page" do
      response = scottish_get_assessors_by_date(
        start_date:,
        end_date:,
      )

      response_json = JSON.parse(response.body)

      expect(response_json["links"]).to eq(JSON.parse(
                                             { next: nil,
                                               self: "#{url}?startDate=#{start_date}&endDate=#{end_date}",
                                               prev: nil }.to_json,
                                           ))
    end

    it "returns an empty list if there is no data" do
      response = scottish_get_assessors_by_date(
        start_date: "2010-06-20",
        end_date: "2010-06-22",
      )

      response_json = JSON.parse(response.body)

      expect(response_json["data"]).to eq(JSON.parse(
                                            { newAssessors: [] }.to_json,
                                          ))
    end
  end

  describe "error scenarios" do
    it "raises an error if you provide a date in the wrong format" do
      response = scottish_get_assessors_by_date(
        start_date: "2021-06-01",
        end_date: "not a date",
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "JSON failed schema validation. Error: The property '#/endDate' Must be date in format YYYY-MM-DD"
    end

    it "raises an error if you request a page out of range" do
      response = scottish_get_assessors_by_date(
        start_date:,
        end_date:,
        page: 2,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "The requested page number 2 is out of range. There are 1 pages."
    end

    it "raises an error if you make a request a date range including today" do
      response = scottish_get_assessors_by_date(
        start_date: "2010-06-20",
        end_date: Date.today.to_s,
        page: 1,
        accepted_responses: [400],
      )

      response_json = JSON.parse(response.body)

      expect(response_json["errors"][0]["title"]).to eq "A required argument is is invalid: date range includes today"
    end

    it "raises an error if you make a request with the date range reversed" do
      response = scottish_get_assessors_by_date(
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
