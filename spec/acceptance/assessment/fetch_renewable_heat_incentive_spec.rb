# frozen_string_literal: true

require "date"

describe "Acceptance::Assessment::FetchRenewableHeatIncentive" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticRdSap: "ACTIVE",
        domesticSap: "INACTIVE",
        nonDomesticSp3: "INACTIVE",
        nonDomesticCc4: "INACTIVE",
        nonDomesticDec: "INACTIVE",
        nonDomesticNos3: "INACTIVE",
        nonDomesticNos4: "STRUCKOFF",
        nonDomesticNos5: "SUSPENDED",
        gda: "INACTIVE",
      },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end


  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_renewable_heat_incentive("123", [401], false)
    end

    it "rejects a request with the wrong scopes" do
      fetch_renewable_heat_incentive("124", [403], true, {}, %w[wrong:scope])
    end
  end

  context "when a domestic assessment doesnt exist" do
    it "returns status 404 for a get" do
      fetch_renewable_heat_incentive("DOESNT-EXIST", [404])
    end

    it "returns an error message structure" do
      response_body = fetch_renewable_heat_incentive("DOESNT-EXIST", [404]).body
      expect(JSON.parse(response_body)).to eq(
        {
          "errors" => [
            { "code" => "NOT_FOUND", "title" => "Assessment not found" },
          ],
        },
      )
    end
  end

  context "when fetching a domestic assessment exists" do
    it "returns status 200" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-17.1"

      response = fetch_renewable_heat_incentive("0000-0000-0000-0000-0000")
      expect(response.status).to eq(200)
    end

    it "returns the assessment details" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body({ domesticSap: "ACTIVE" }),
      )
      lodge_assessment(
        assessment_body: valid_sap_xml,
        accepted_responses: [201],
        schema_name: "SAP-Schema-17.1",
        auth_data: { scheme_ids: [scheme_id] },
      )

      response =
        JSON.parse(
          fetch_renewable_heat_incentive("0000-0000-0000-0000-0000").body,
        )

      expected_response =
        JSON.parse(
          {
            epcRrn: "0000-0000-0000-0000-0000",
            assessorName: "SPEC000000",
            reportType: "Energy Performance Certificate",
            inspectionDate: "2020-01-30",
            lodgementDate: "2020-02-29",
            dwellingType: "Top-floor flat",
            postcode: "SW1P 4JA",
            propertyAgeBand: "D",
            tenure: "Owner-occupied",
            totalFloorArea: "123.5 square metres",
            cavityWallInsulation: false,
            loftInsulation: true,
            spaceHeating: "Gas-fired central heating",
            waterHeating: "Electrical immersion heater",
            secondaryHeating: "Electric bar heater",
            energyEfficiency: {
              currentRating: 64,
              currentBand: "d",
              potentialRating: 75,
              potentialBand: "c",
            },
          }.to_json,
        )
      expect(response["data"]).to eq(expected_response)
    end
  end
end
