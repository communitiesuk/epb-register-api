# frozen_string_literal: true

describe "Acceptance::Assessor" do
  include RSpecAssessorServiceMixin
  let(:valid_assessor_request) do
    {
      firstName: "Some",
      middleNames: "Middle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticSap: "ACTIVE",
        domesticRdSap: "ACTIVE",
        nonDomesticSp3: "ACTIVE",
        nonDomesticCc4: "ACTIVE",
        nonDomesticDec: "ACTIVE",
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "ACTIVE",
      },
    }
  end

  def assessor_without_key(missing, request_body = nil)
    request_body ||= valid_assessor_request
    assessor = request_body.dup
    assessor.delete(missing)
    assessor
  end

  context "when a scheme doesn't exist" do
    it "returns status 404 for a get" do
      fetch_assessor(20, "SCHEME4233", [404])
    end

    it "returns status 404 for a PUT" do
      add_assessor(20, "SCHEME4532", valid_assessor_request, [404])
    end
  end

  context "when an assessor doesn't exist" do
    let!(:scheme_id) { add_scheme_and_get_id }

    it "returns status 404" do
      fetch_assessor(scheme_id, "SCHE2354246", [404])
    end
  end

  context "when getting an assessor on the wrong scheme" do
    it "returns status 404" do
      scheme_id = add_scheme_and_get_id
      second_scheme_id = add_scheme_and_get_id("second scheme")
      add_assessor(second_scheme_id, "SCHE987654", valid_assessor_request)
      fetch_assessor(scheme_id, "SCHE987654", [404])
    end
  end

  context "when getting an assessor" do
    context "and the assessor exists on the correct scheme" do
      it "returns status 200 for a get" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "SCHEME4233", valid_assessor_request)
        expect(fetch_assessor(scheme_id, "SCHEME4233").status).to eq(200)
      end

      it "returns json" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "SCHEME4233", valid_assessor_request)
        expect(
          fetch_assessor(scheme_id, "SCHEME4233").headers["Content-type"],
        ).to eq("application/json")
      end

      it "returns the correct details for the assessor" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "SCHEME4233", valid_assessor_request)
        expected_response =
          JSON.parse(
            {
              data: {
                registeredBy: { schemeId: scheme_id, name: "test scheme" },
                schemeAssessorId: "SCHEME4233",
                firstName: valid_assessor_request[:firstName],
                middleNames: valid_assessor_request[:middleNames],
                lastName: valid_assessor_request[:lastName],
                dateOfBirth: valid_assessor_request[:dateOfBirth],
                contactDetails: valid_assessor_request[:contactDetails],
                searchResultsComparisonPostcode: "",
                qualifications: {
                  domesticSap: "ACTIVE",
                  domesticRdSap: "ACTIVE",
                  nonDomesticSp3: "ACTIVE",
                  nonDomesticCc4: "ACTIVE",
                  nonDomesticDec: "ACTIVE",
                  nonDomesticNos3: "ACTIVE",
                  nonDomesticNos4: "ACTIVE",
                  nonDomesticNos5: "ACTIVE",
                },
              },
              meta: {},
            }.to_json,
          )
        response = JSON.parse(fetch_assessor(scheme_id, "SCHEME4233").body)
        expect(response).to eq(expected_response)
      end

      it "returns EPC domestic qualification as inactive by default" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          "SCHEME4233",
          assessor_without_key(:qualifications),
        )
        response = JSON.parse(fetch_assessor(scheme_id, "SCHEME4233").body)
        expect(response["data"]["qualifications"]["domesticRdSap"]).to eq(
          "INACTIVE",
        )
      end
    end

    context "security" do
      it "rejects a request that is not authenticated" do
        fetch_assessor(2, "test", [401], false)
      end

      it "rejects a request without the right scope" do
        fetch_assessor(2, "test", [403], true, {}, %w[wrong:scope])
      end

      it "rejects a request with the right scope but from the wrong scheme" do
        scheme_id = add_scheme_and_get_id
        wrong_scheme_id = scheme_id + 10
        add_assessor(scheme_id, "test", valid_assessor_request)

        fetch_assessor(
          scheme_id,
          "test",
          [403],
          true,
          { scheme_ids: [wrong_scheme_id] },
        )
      end
    end
  end

  context "when creating an assessor" do
    context "security" do
      it "rejects a request which is not authenticated" do
        add_assessor(20, "SCHEME4532", valid_assessor_request, [401], false)
      end

      it "rejects a request that doesnt have the right scopes" do
        add_assessor(
          20,
          "SCHEME4532",
          valid_assessor_request,
          [403],
          true,
          {},
          %w[wrong:scope],
        )
      end

      it "rejects a request that is from the wrong scheme but has the right scope" do
        scheme_id = add_scheme_and_get_id
        wrong_scheme_id = scheme_id + 10
        add_assessor(
          scheme_id,
          "TEST",
          valid_assessor_request,
          [403],
          true,
          { 'scheme_ids': [wrong_scheme_id] },
          %w[scheme:assessor:update],
        )
      end
    end

    context "which is valid with all fields" do
      it "returns 201 created" do
        scheme_id = add_scheme_and_get_id
        assessor_response =
          add_assessor(scheme_id, "SCHE55443", valid_assessor_request)

        expect(assessor_response.status).to eq(201)
      end

      it "returns JSON" do
        scheme_id = add_scheme_and_get_id
        assessor_response =
          add_assessor(scheme_id, "SCHE55443", valid_assessor_request)

        expect(assessor_response.headers["Content-type"]).to eq(
          "application/json",
        )
      end

      it "returns assessor details with scheme details" do
        scheme_id = add_scheme_and_get_id
        assessor_response =
          JSON.parse(
            add_assessor(scheme_id, "SCHE55443", valid_assessor_request).body,
          )[
            "data"
          ]

        expected_response =
          JSON.parse(
            {
              registeredBy: { schemeId: scheme_id.to_s, name: "test scheme" },
              schemeAssessorId: "SCHE55443",
              firstName: valid_assessor_request[:firstName],
              middleNames: valid_assessor_request[:middleNames],
              lastName: valid_assessor_request[:lastName],
              dateOfBirth: valid_assessor_request[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request[:searchResultsComparisonPostcode],
              qualifications: {
                domesticSap: "ACTIVE",
                domesticRdSap: "ACTIVE",
                nonDomesticSp3: "ACTIVE",
                nonDomesticCc4: "ACTIVE",
                nonDomesticDec: "ACTIVE",
                nonDomesticNos3: "ACTIVE",
                nonDomesticNos4: "ACTIVE",
                nonDomesticNos5: "ACTIVE",
              },
              contactDetails: {
                email: "person@person.com", telephoneNumber: "010199991010101"
              },
            }.to_json,
          )

        expect(assessor_response).to eq(expected_response)
      end
    end

    context "which is valid with optional fields missing" do
      it "returns 201 created" do
        scheme_id = add_scheme_and_get_id
        assessor_response =
          add_assessor(
            scheme_id,
            "SCHE55443",
            assessor_without_key(:middleNames),
          )

        expect(assessor_response.status).to eq(201)
      end

      it "returns assessor details with scheme details" do
        scheme_id = add_scheme_and_get_id
        assessor_response =
          JSON.parse(
            add_assessor(
              scheme_id,
              "SCHE55443",
              assessor_without_key(:middleNames),
            )
              .body,
          )[
            "data"
          ]

        expected_response =
          JSON.parse(
            {
              registeredBy: { schemeId: scheme_id.to_s, name: "test scheme" },
              schemeAssessorId: "SCHE55443",
              firstName: valid_assessor_request[:firstName],
              lastName: valid_assessor_request[:lastName],
              dateOfBirth: valid_assessor_request[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request[:searchResultsComparisonPostcode],
              qualifications: valid_assessor_request[:qualifications],
              contactDetails: valid_assessor_request[:contactDetails],
            }.to_json,
          )

        expect(assessor_response).to eq(expected_response)
      end
    end

    context "which is invalid" do
      it "rejects anything that isn't JSON" do
        scheme_id = add_scheme_and_get_id
        assertive_put(
          "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
          ">>>this is not json<<<",
          [422],
          true,
          { 'scheme_ids': [scheme_id] },
          %w[scheme:assessor:update],
        )
      end

      it "rejects an empty request body" do
        scheme_id = add_scheme_and_get_id
        assertive_put(
          "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
          {},
          [422],
          true,
          { 'scheme_ids': [scheme_id] },
          %w[scheme:assessor:update],
        )
      end

      it "rejects requests without firstname" do
        add_scheme_then_assessor(assessor_without_key(:firstName), [422])
      end

      it "rejects requests without last name" do
        add_scheme_then_assessor(assessor_without_key(:lastName), [422])
      end

      it "rejects requests without date of birth" do
        add_scheme_then_assessor(assessor_without_key(:dateOfBirth), [422])
      end

      it "rejects requests with invalid date of birth" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:dateOfBirth] = "02/28/1987"
        add_scheme_then_assessor(invalid_body, [422])
      end

      it "rejects requests with invalid first name" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:firstName] = 1_000
        add_scheme_then_assessor(invalid_body, [422])
      end

      it "rejects requests with invalid last name" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:lastName] = false
        add_scheme_then_assessor(invalid_body, [422])
      end

      it "rejects requests with invalid middle names" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:middleNames] = %w[adsfasd]
        add_scheme_then_assessor(invalid_body, [422])
      end

      it "rejects an assessor qualification that isnt a valid status" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:qualifications] = { domesticRdSap: "horse" }
        add_scheme_then_assessor(invalid_body, [422])
      end

      it "rejects a search results comparison postcode that isnt a string" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:searchResultsComparisonPostcode] = 25
        add_scheme_then_assessor(invalid_body, [422])
      end
    end

    context "which has a clashing ID for an assessor on another scheme" do
      it "Returns a status code 409" do
        first_scheme = add_scheme_and_get_id
        second_scheme = add_scheme_and_get_id "scheme two"

        add_assessor(first_scheme, "SCHE4001", valid_assessor_request)
        add_assessor(second_scheme, "SCHE4001", valid_assessor_request, [409])
      end
    end

    context "which has an escaped assessor scheme id" do
      let(:escaped_assessor_scheme_id) { "TEST%2F000000" }

      it "adds an assessor" do
        scheme_id = add_scheme_and_get_id

        add_assessor_response =
          add_assessor scheme_id,
                       escaped_assessor_scheme_id,
                       valid_assessor_request

        expect(add_assessor_response.status).to eq 201
      end

      it "fetches an assessor" do
        scheme_id = add_scheme_and_get_id

        add_assessor scheme_id,
                     escaped_assessor_scheme_id,
                     valid_assessor_request

        fetch_assessor_response =
          fetch_assessor(scheme_id, escaped_assessor_scheme_id)

        expect(fetch_assessor_response.status).to eq 200
      end
    end
  end

  context "when updating an assessor" do
    context "which is valid with all fields" do
      it "returns 200 on the update" do
        scheme_id = add_scheme_and_get_id
        assessor = valid_assessor_request
        add_assessor(scheme_id, "ASSESSOR99", assessor)
        assessor[:firstName] = "Janine"
        second_response = add_assessor(scheme_id, "ASSESSOR99", assessor)
        expect(second_response.status).to eq(200)
      end

      it "replaces a previous assessors details successfully" do
        scheme_id = add_scheme_and_get_id
        assessor = valid_assessor_request
        add_assessor(scheme_id, "ASSESSOR99", assessor)

        assessor[:firstName] = "Janine"
        add_assessor(scheme_id, "ASSESSOR99", assessor)

        response = fetch_assessor(scheme_id, "ASSESSOR99")

        expected_response = valid_assessor_request
        expected_response[:registeredBy] = {
          schemeId: scheme_id, name: "test scheme"
        }
        expected_response[:schemeAssessorId] = "ASSESSOR99"
        expected_response[:firstName] = "Janine"
        expect(JSON.parse(response.body)["data"]).to eq(
          JSON.parse(expected_response.to_json),
        )
      end
    end

    context "which has an invalid email" do
      it "rejects the assessor" do
        invalid_request_body = valid_assessor_request
        invalid_request_body[:contactDetails][:email] = "54"

        add_scheme_then_assessor(invalid_request_body, [422])
      end
    end

    context "which has a valid email" do
      it "saves it successfully" do
        scheme_id = add_scheme_and_get_id

        request_body = valid_assessor_request
        request_body[:contactDetails][:email] = "mar@ten.com"

        add_assessor(scheme_id, "ASSESSOR99", request_body).body

        response_body = fetch_assessor(scheme_id, "ASSESSOR99").body
        json_response = JSON.parse(response_body)

        expect(json_response["data"]["contactDetails"]["email"]).to eq(
          "mar@ten.com",
        )
      end
    end

    context "which has an invalid phone number" do
      it "returns error 400" do
        request_body = valid_assessor_request
        request_body[:contactDetails][:telephoneNumber] = "0" * 257
        add_scheme_then_assessor(request_body, [422])
      end
    end

    context "which has a valid phone number" do
      it "successfully saves it" do
        scheme_id = add_scheme_and_get_id

        valid_telephone = "0" * 256

        request_body = valid_assessor_request
        request_body[:contactDetails][:telephoneNumber] = valid_telephone

        add_assessor(scheme_id, "ASSESSOR99", request_body)

        response_body = fetch_assessor(scheme_id, "ASSESSOR99").body

        json_response = JSON.parse(response_body)

        expect(
          json_response["data"]["contactDetails"]["telephoneNumber"],
        ).to eq(valid_telephone)
      end
    end
  end
end
