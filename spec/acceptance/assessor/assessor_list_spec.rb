# frozen_string_literal: true

describe "Acceptance::AssessorList" do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticRdSap: "ACTIVE" },
      contact_details: {
        email: "someone@energy.gov", telephone_number: "01234 567"
      },
    }
  end

  context "when a scheme doesn't exist" do
    context "when a client is authorised" do
      it "returns status 404 for a get" do
        fetch_assessors(20, [404], true, { 'scheme_ids': [20] })
      end

      it "returns the 404 error response" do
        response = fetch_assessors(20, [404], true, { 'scheme_ids': [20] })
        expect(response.body).to eq(
          {
            errors: [
              {
                "code": "NOT_FOUND", title: "The requested scheme was not found"
              },
            ],
          }.to_json,
        )
      end
    end

    context "when a client is not authorised" do
      it "returns status 403 for a get" do
        fetch_assessors(20, [403], true)
      end

      it "returns the 403 error response for a get" do
        response = fetch_assessors(20, [403], true)
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
      fetch_assessors(scheme_id, [200], true, { 'scheme_ids': [scheme_id] })
    end

    it "returns an empty list" do
      scheme_id = add_scheme_and_get_id
      expected = { "assessors" => [] }
      response =
        fetch_assessors(scheme_id, [200], true, { 'scheme_ids': [scheme_id] })

      actual = JSON.parse(response.body)["data"]

      expect(actual).to eq expected
    end

    it "returns JSON for a get" do
      scheme_id = add_scheme_and_get_id
      response =
        fetch_assessors(scheme_id, [200], true, { 'scheme_ids': [scheme_id] })

      expect(response.headers["Content-type"]).to eq("application/json")
    end
  end

  context "when a scheme has one assessor" do
    it "returns an array of assessors" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SCHEME4233", valid_assessor_request_body)
      response =
        fetch_assessors(scheme_id, [200], true, { 'scheme_ids': [scheme_id] })

      actual = JSON.parse(response.body)["data"]
      expected = {
        "assessors" => [
          {
            "registeredBy" => {
              "schemeId" => scheme_id, "name" => "test scheme"
            },
            "schemeAssessorId" => "SCHEME4233",
            "firstName" => valid_assessor_request_body[:firstName],
            "middleNames" => valid_assessor_request_body[:middleNames],
            "lastName" => valid_assessor_request_body[:lastName],
            "dateOfBirth" => valid_assessor_request_body[:dateOfBirth],
            "contactDetails" => {
              "telephoneNumber" => "01234 567", "email" => "someone@energy.gov"
            },
            "searchResultsComparisonPostcode" => "",
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
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
      add_assessor(scheme_id, "SCHEME1234", valid_assessor_request_body)
      add_assessor(scheme_id, "SCHEME5678", valid_assessor_request_body)

      response =
        fetch_assessors(scheme_id, [200], true, { 'scheme_ids': [scheme_id] })
      actual = JSON.parse(response.body)["data"]
      expected = {
        "assessors" => [
          {
            "registeredBy" => {
              "schemeId" => scheme_id, "name" => "test scheme"
            },
            "schemeAssessorId" => "SCHEME5678",
            "firstName" => valid_assessor_request_body[:firstName],
            "middleNames" => valid_assessor_request_body[:middleNames],
            "lastName" => valid_assessor_request_body[:lastName],
            "dateOfBirth" => valid_assessor_request_body[:dateOfBirth],
            "contactDetails" => {
              "telephoneNumber" => "01234 567", "email" => "someone@energy.gov"
            },
            "searchResultsComparisonPostcode" => "",
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
            },
          },
          {
            "registeredBy" => {
              "schemeId" => scheme_id, "name" => "test scheme"
            },
            "schemeAssessorId" => "SCHEME1234",
            "firstName" => valid_assessor_request_body[:firstName],
            "middleNames" => valid_assessor_request_body[:middleNames],
            "lastName" => valid_assessor_request_body[:lastName],
            "dateOfBirth" => valid_assessor_request_body[:dateOfBirth],
            "contactDetails" => {
              "telephoneNumber" => "01234 567", "email" => "someone@energy.gov"
            },
            "searchResultsComparisonPostcode" => "",
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "ACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "INACTIVE",
              "nonDomesticNos4" => "INACTIVE",
              "nonDomesticNos5" => "INACTIVE",
            },
          },
        ],
      }

      expect(expected["assessors"]).to match_array actual["assessors"]
    end
  end

  context "when a client is not authenticated" do
    it "returns a 401 unauthorised" do
      scheme_id = add_scheme_and_get_id
      fetch_assessors(scheme_id, [401], false)
    end
  end

  context "when a client does not have the right scope" do
    it "returns a 403 forbidden" do
      scheme_id = add_scheme_and_get_id
      fetch_assessors(scheme_id, [403])
    end
  end

  context "when a client tries to access another clients assessors" do
    it "returns a 403 forbidden" do
      scheme_id = add_scheme_and_get_id
      second_scheme_id = add_scheme_and_get_id("second test scheme")

      fetch_assessors(
        second_scheme_id,
        [403],
        true,
        { 'scheme_ids': [scheme_id] },
      )
    end
  end

  context "when supplemental data object does not contain the schemes_ids key" do
    it "returns a 403 forbidden" do
      scheme_id = add_scheme_and_get_id
      fetch_assessors(scheme_id, [403], true, { 'test': [scheme_id] })
    end
  end
end
