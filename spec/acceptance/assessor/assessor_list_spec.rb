# frozen_string_literal: true

describe "Acceptance::AssessorList" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "INACTIVE",
        non_domestic_sp3: "INACTIVE",
        non_domestic_cc4: "INACTIVE",
        nonDomesticDec: "INACTIVE",
        non_domestic_nos3: "INACTIVE",
        non_domestic_nos4: "INACTIVE",
        non_domestic_nos5: "INACTIVE",
        gda: "INACTIVE",
      },
      contact_details: {
        email: "someone@energy.gov",
        telephone_number: "01234 567",
      },
    }
  end

  context "when a scheme doesn't exist" do
    context "when a client is authorised" do
      it "returns status 404 for a get" do
        expect(fetch_assessors(scheme_id: 20, accepted_responses: [404], auth_data: { 'scheme_ids': [20] }).status).to eq(404)
      end

      it "returns the 404 error response" do
        response = fetch_assessors(scheme_id: 20, accepted_responses: [404], auth_data: { 'scheme_ids': [20] })
        expect(response.body).to eq(
          {
            errors: [
              {
                "code": "NOT_FOUND",
                title: "The requested scheme was not found",
              },
            ],
          }.to_json,
        )
      end
    end

    context "when a client is not authorised" do
      it "returns status 403 for a get" do
        expect(fetch_assessors(scheme_id: 20, accepted_responses: [403]).status).to eq(403)
      end

      it "returns the 403 error response for a get" do
        response = fetch_assessors(scheme_id: 20, accepted_responses: [403])
        expect(response.body).to eq(
          {
            errors: [
              {
                "code": "UNAUTHORISED",
                title: "You are not authorised to perform this request",
              },
            ],
          }.to_json,
        )
      end
    end
  end

  context "when a scheme has no assessors" do
    it "returns status 200 for a get" do
      scheme_id = add_scheme_and_get_id
      expect(fetch_assessors(scheme_id:, auth_data: { 'scheme_ids': [scheme_id] }).status).to eq(200)
    end

    it "returns an empty list" do
      scheme_id = add_scheme_and_get_id
      expected = { "assessors" => [] }
      response =
        fetch_assessors(scheme_id:, auth_data: { 'scheme_ids': [scheme_id] })

      actual = JSON.parse(response.body)["data"]

      expect(actual).to eq expected
    end

    it "returns JSON for a get" do
      scheme_id = add_scheme_and_get_id
      response =
        fetch_assessors(scheme_id:, auth_data: { 'scheme_ids': [scheme_id] })

      expect(response.headers["Content-type"]).to eq("application/json")
    end
  end

  context "when a scheme has one assessor" do
    it "returns an array of assessors" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SCHE423344", body: valid_assessor_request_body)
      response =
        fetch_assessors(scheme_id:, auth_data: { 'scheme_ids': [scheme_id] })

      actual = JSON.parse(response.body)["data"]
      expected = {
        "assessors" => [
          {
            "registeredBy" => {
              "schemeId" => scheme_id,
              "name" => "test scheme",
            },
            "schemeAssessorId" => "SCHE423344",
            "firstName" => valid_assessor_request_body[:firstName],
            "middleNames" => valid_assessor_request_body[:middleNames],
            "lastName" => valid_assessor_request_body[:lastName],
            "dateOfBirth" => valid_assessor_request_body[:dateOfBirth],
            "contactDetails" => {
              "telephoneNumber" => "01234 567",
              "email" => "someone@energy.gov",
            },
            "searchResultsComparisonPostcode" => "",
            "address" => {},
            "companyDetails" => {},
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
          },
        ],
      }

      expect(actual).to eq expected
    end
  end

  context "when a scheme has multiple assessors" do
    it "returns an array of assessors" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id:, assessor_id: "SCHE123456", body: valid_assessor_request_body)
      add_assessor(scheme_id:, assessor_id: "SCHE567890", body: valid_assessor_request_body)

      response =
        fetch_assessors(scheme_id:, auth_data: { 'scheme_ids': [scheme_id] })
      actual = JSON.parse(response.body)["data"]
      expected = {
        "assessors" => [
          {
            "registeredBy" => {
              "schemeId" => scheme_id,
              "name" => "test scheme",
            },
            "schemeAssessorId" => "SCHE123456",
            "firstName" => valid_assessor_request_body[:firstName],
            "middleNames" => valid_assessor_request_body[:middleNames],
            "lastName" => valid_assessor_request_body[:lastName],
            "dateOfBirth" => valid_assessor_request_body[:dateOfBirth],
            "contactDetails" => {
              "telephoneNumber" => "01234 567",
              "email" => "someone@energy.gov",
            },
            "searchResultsComparisonPostcode" => "",
            "address" => {},
            "companyDetails" => {},
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
          },
          {
            "registeredBy" => {
              "schemeId" => scheme_id,
              "name" => "test scheme",
            },
            "schemeAssessorId" => "SCHE567890",
            "firstName" => valid_assessor_request_body[:firstName],
            "middleNames" => valid_assessor_request_body[:middleNames],
            "lastName" => valid_assessor_request_body[:lastName],
            "dateOfBirth" => valid_assessor_request_body[:dateOfBirth],
            "contactDetails" => {
              "telephoneNumber" => "01234 567",
              "email" => "someone@energy.gov",
            },
            "searchResultsComparisonPostcode" => "",
            "address" => {},
            "companyDetails" => {},
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
          },
        ],
      }

      expect(expected["assessors"]).to match_array actual["assessors"]
    end
  end

  context "when a client is not authenticated" do
    it "returns a 401 unauthorised" do
      expect(fetch_assessors(scheme_id: add_scheme_and_get_id, accepted_responses: [401], should_authenticate: false).status).to eq(401)
    end
  end

  context "when a client does not have the right scope" do
    it "returns a 403 forbidden" do
      expect(fetch_assessors(scheme_id: add_scheme_and_get_id, accepted_responses: [403], scopes: []).status).to eq(403)
    end
  end

  context "when a client tries to access another clients assessors" do
    it "returns a 403 forbidden" do
      scheme_id = add_scheme_and_get_id
      second_scheme_id = add_scheme_and_get_id(name: "second test scheme")

      expect(fetch_assessors(
        scheme_id: second_scheme_id,
        accepted_responses: [403],
        auth_data: { 'scheme_ids': [scheme_id] },
      ).status).to eq(403)
    end
  end

  context "when supplemental data object does not contain the schemes_ids key" do
    it "returns a 403 forbidden" do
      scheme_id = add_scheme_and_get_id
      expect(fetch_assessors(scheme_id:, accepted_responses: [403], auth_data: { 'test': [scheme_id] }).status).to eq(403)
    end
  end
end
