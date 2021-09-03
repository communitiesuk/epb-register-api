# frozen_string_literal: true

describe "Acceptance::Assessor" do
  include RSpecRegisterApiServiceMixin
  let(:valid_assessor_request) do
    {
      firstName: "Some",
      middleNames: "Middle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      contactDetails: {
        telephoneNumber: "010199991010101",
        email: "person@person.com",
      },
      searchResultsComparisonPostcode: "",
      alsoKnownAs: "Bob",
      address: {
        addressLine1: "Flat 33",
        addressLine2: "18 Palmtree Road",
        addressLine3: "",
        town: "Brighton",
        postcode: "SE1 7EZ",
      },
      companyDetails: {
        companyRegNo: "",
        companyAddressLine1: "1 Company Building",
        companyAddressLine2: "Company Street",
        companyAddressLine3: "Oraganisation district",
        companyTown: "Monoploy",
        companyPostcode: "NE53 2WS",
        companyWebsite: "companny@test.uk",
        companyTelephoneNumber: "00000002000",
        companyEmail: "emailme@company.org",
        companyName: "My Company",
      },
      qualifications: {
        domesticSap: "ACTIVE",
        domesticRdSap: "ACTIVE",
        nonDomesticSp3: "ACTIVE",
        nonDomesticCc4: "ACTIVE",
        nonDomesticDec: "ACTIVE",
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "ACTIVE",
        gda: "ACTIVE",
      },
    }
  end

  let!(:scheme_id) { add_scheme_and_get_id }

  def assessor_without_key(missing, request_body = nil)
    request_body ||= valid_assessor_request
    assessor = request_body.dup
    assessor.delete(missing)
    assessor
  end

  context "when a scheme doesn't exist" do
    it "returns status 404 for a get" do
      fetch_assessor(scheme_id: 666, assessor_id: "SCHE423344", accepted_responses: [404])
    end

    it "returns status 404 for a PUT" do
      add_assessor(scheme_id: 666, assessor_id: "SCHE453222", body: valid_assessor_request, accepted_responses: [404])
    end
  end

  context "when an assessor doesn't exist" do
    it "returns status 404" do
      fetch_assessor(scheme_id: scheme_id, assessor_id: "SCHE2354246", accepted_responses: [404])
    end
  end

  context "when getting an assessor on the wrong scheme" do
    it "returns status 404" do
      second_scheme_id = add_scheme_and_get_id(name: "second scheme")
      add_assessor(scheme_id: second_scheme_id, assessor_id: "SCHE987654", body: valid_assessor_request)
      fetch_assessor(scheme_id: scheme_id, assessor_id: "SCHE987654", accepted_responses: [404])
    end
  end

  context "when getting an assessor" do
    context "when the assessor exists on the correct scheme" do
      it "returns status 200 for a get" do
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
        expect(fetch_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344").status).to eq(200)
      end

      it "returns json" do
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
        expect(
          fetch_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344").headers["Content-type"],
        ).to eq("application/json")
      end

      it "returns the correct details for the assessor" do
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
        expected_response =
          JSON.parse(
            {
              data: {
                registeredBy: {
                  schemeId: scheme_id,
                  name: "test scheme",
                },
                schemeAssessorId: "SCHE423344",
                firstName: valid_assessor_request[:firstName],
                middleNames: valid_assessor_request[:middleNames],
                lastName: valid_assessor_request[:lastName],
                dateOfBirth: valid_assessor_request[:dateOfBirth],
                contactDetails: valid_assessor_request[:contactDetails],
                searchResultsComparisonPostcode:
                  valid_assessor_request[:searchResultsComparisonPostcode],
                alsoKnownAs: valid_assessor_request[:alsoKnownAs],
                address: valid_assessor_request[:address],
                companyDetails: valid_assessor_request[:companyDetails],
                qualifications: {
                  domesticSap: "ACTIVE",
                  domesticRdSap: "ACTIVE",
                  nonDomesticSp3: "ACTIVE",
                  nonDomesticCc4: "ACTIVE",
                  nonDomesticDec: "ACTIVE",
                  nonDomesticNos3: "ACTIVE",
                  nonDomesticNos4: "ACTIVE",
                  nonDomesticNos5: "ACTIVE",
                  gda: "ACTIVE",
                },
              },
              meta: {},
            }.to_json,
          )
        response = JSON.parse(fetch_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344").body)
        expect(response).to eq(expected_response)
      end

      it "returns EPC domestic qualification as inactive by default" do
        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "SCHE423344",
          body: assessor_without_key(:qualifications),
        )
        response = JSON.parse(fetch_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344").body)
        expect(response["data"]["qualifications"]["domesticRdSap"]).to eq(
          "INACTIVE",
        )
      end
    end

    describe "security scenarios" do
      it "rejects a request that is not authenticated" do
        fetch_assessor(scheme_id: 2, assessor_id: "test", accepted_responses: [401], should_authenticate: false)
      end

      it "rejects a request without the right scope" do
        fetch_assessor(scheme_id: 2, assessor_id: "test", accepted_responses: [403], should_authenticate: true, scopes: %w[wrong:scope])
      end

      it "rejects a request with the right scope but from the wrong scheme" do
        wrong_scheme_id = scheme_id + 10
        add_assessor(scheme_id: scheme_id, assessor_id: "TEST123456", body: valid_assessor_request)

        fetch_assessor(
          scheme_id: scheme_id,
          assessor_id: "test",
          accepted_responses: [403],
          auth_data: { scheme_ids: [wrong_scheme_id] },
        )
      end
    end
  end

  context "when checking an assessor's current qualification status" do
    let(:assessor_response) do
      {
        registeredBy: {
          schemeId: scheme_id,
          name: "test scheme",
        },
        schemeAssessorId: "SCHE423344",
        firstName: valid_assessor_request[:firstName],
        middleNames: valid_assessor_request[:middleNames],
        lastName: valid_assessor_request[:lastName],
        contactDetails: valid_assessor_request[:contactDetails],
        searchResultsComparisonPostcode:
          valid_assessor_request[:searchResultsComparisonPostcode],
        alsoKnownAs: valid_assessor_request[:alsoKnownAs],
        address: valid_assessor_request[:address],
        companyDetails: valid_assessor_request[:companyDetails],
        qualifications: {
          domesticSap: "ACTIVE",
          domesticRdSap: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          gda: "ACTIVE",
        },
      }
    end

    it "raises an error when incorrect params are provided" do
      response =
        JSON.parse(
          fetch_assessor_current_status(first_name: "Some", last_name: "Person", scheme_id: scheme_id, accepted_responses: [400])
            .body,
        )
      expect(response["errors"].first["title"]).to eq("Must specify first name, last name and a valid date of birth when searching")
    end

    it "raises an error when invalid params are provided" do
      response =
        JSON.parse(
          fetch_assessor_current_status(
            first_name: "Some",
            last_name: "Person",
            date_of_birth: "not_a_date",
            scheme_id: scheme_id,
            accepted_responses: [400],
          ).body,
        )
      expect(response["errors"].first["title"]).to eq(
        "Must specify first name, last name and a valid date of birth when searching",
      )
    end

    it "will raise an error if given the incorrect auth scope" do
      response =
        JSON.parse(
          fetch_assessor_current_status(
            first_name: "Some",
            last_name: "Person",
            date_of_birth: "1991-02-25",
            scheme_id: scheme_id,
            accepted_responses: [403],
            scopes: %w[assessor:search],
          ).body,
        )
      expect(response["errors"].first["title"]).to eq("You are not authorised to perform this request")
    end

    it "returns an empty array when there are no matching assessors" do
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
      response =
        JSON.parse(fetch_assessor_current_status(
          first_name: "Flitwick",
          last_name: "Person",
          date_of_birth: "1991-02-25",
          scheme_id: scheme_id,
        ).body)
      expect(response["data"]).to eq([])
    end

    it "returns the correct details for the specific assessor matching all three params" do
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
      request_body = valid_assessor_request.dup
      request_body[:firstName] = "Stan"
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423444", body: request_body)
      expected_response =
        JSON.parse({ data: [assessor_response], meta: {} }.to_json)

      response =
        JSON.parse(
          fetch_assessor_current_status(
            first_name: "Some",
            last_name: "Person",
            date_of_birth: "1991-02-25",
            scheme_id: scheme_id,
          ).body,
        )
      expect(response).to eq(expected_response)
    end

    it "returns the correct details when given names with different capitalization" do
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
      request_body = valid_assessor_request.dup
      request_body[:firstName] = "Stan"
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423444", body: request_body)
      expected_response =
        JSON.parse({ data: [assessor_response], meta: {} }.to_json)

      response =
        JSON.parse(
          fetch_assessor_current_status(
            first_name: "sOmE",
            last_name: "pErSoN",
            date_of_birth: "1991-02-25",
            scheme_id: scheme_id,
          ).body,
        )
      expect(response).to eq(expected_response)
    end

    it "returns the correct details when given partial names" do
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423344", body: valid_assessor_request)
      request_body = valid_assessor_request.dup
      request_body[:firstName] = "Stan"
      add_assessor(scheme_id: scheme_id, assessor_id: "SCHE423444", body: request_body)
      expected_response =
        JSON.parse({ data: [assessor_response], meta: {} }.to_json)

      response =
        JSON.parse(
          fetch_assessor_current_status(first_name: "sO", last_name: "pErS", date_of_birth: "1991-02-25", scheme_id: scheme_id)
            .body,
        )
      expect(response).to eq(expected_response)
    end
  end

  context "when creating an assessor" do
    describe "security scenarios" do
      it "rejects a request which is not authenticated" do
        add_assessor(
          scheme_id: 20,
          assessor_id: "SCHEME4532",
          body: valid_assessor_request,
          accepted_responses: [401],
          should_authenticate: false,
        )
      end

      it "rejects a request that doesnt have the right scopes" do
        add_assessor(
          scheme_id: 20,
          assessor_id: "SCHEME4532",
          body: valid_assessor_request,
          accepted_responses: [403],
          scopes: %w[wrong:scope],
        )
      end

      it "rejects a request that is from the wrong scheme but has the right scope" do
        wrong_scheme_id = scheme_id + 10
        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "TEST",
          body: valid_assessor_request,
          accepted_responses: [403],
          auth_data: { 'scheme_ids': [wrong_scheme_id] },
          scopes: %w[scheme:assessor:update],
        )
      end
    end

    context "with all fields valid" do
      it "returns 201 created" do
        assessor_response =
          add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: valid_assessor_request)

        expect(assessor_response.status).to eq(201)
      end

      it "returns JSON" do
        assessor_response =
          add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: valid_assessor_request)

        expect(assessor_response.headers["Content-type"]).to eq(
          "application/json",
        )
      end

      it "returns assessor details with scheme details" do
        assessor_response =
          JSON.parse(
            add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: valid_assessor_request).body,
          )[
            "data"
          ]

        expected_response =
          JSON.parse(
            {
              registeredBy: {
                schemeId: scheme_id.to_s,
                name: "test scheme",
              },
              schemeAssessorId: "SCHE554433",
              firstName: valid_assessor_request[:firstName],
              middleNames: valid_assessor_request[:middleNames],
              lastName: valid_assessor_request[:lastName],
              dateOfBirth: valid_assessor_request[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request[:searchResultsComparisonPostcode],
              alsoKnownAs: valid_assessor_request[:alsoKnownAs],
              address: valid_assessor_request[:address],
              companyDetails: valid_assessor_request[:companyDetails],
              qualifications: {
                domesticSap: "ACTIVE",
                domesticRdSap: "ACTIVE",
                nonDomesticSp3: "ACTIVE",
                nonDomesticCc4: "ACTIVE",
                nonDomesticDec: "ACTIVE",
                nonDomesticNos3: "ACTIVE",
                nonDomesticNos4: "ACTIVE",
                nonDomesticNos5: "ACTIVE",
                gda: "ACTIVE",
              },
              contactDetails: {
                email: "person@person.com",
                telephoneNumber: "010199991010101",
              },
            }.to_json,
          )

        expect(assessor_response).to eq(expected_response)
      end
    end

    context "with optional fields missing (but otherwise valid)" do
      it "returns 201 created" do
        assessor_response =
          add_assessor(
            scheme_id: scheme_id,
            assessor_id: "SCHE554433",
            body: assessor_without_key(:middleNames),
          )

        expect(assessor_response.status).to eq(201)
      end

      it "returns assessor details with scheme details" do
        assessor_response =
          JSON.parse(
            add_assessor(
              scheme_id: scheme_id,
              assessor_id: "SCHE554433",
              body: assessor_without_key(:middleNames),
            ).body,
          )[
            "data"
          ]

        expected_response =
          JSON.parse(
            {
              registeredBy: {
                schemeId: scheme_id.to_s,
                name: "test scheme",
              },
              schemeAssessorId: "SCHE554433",
              firstName: valid_assessor_request[:firstName],
              lastName: valid_assessor_request[:lastName],
              dateOfBirth: valid_assessor_request[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request[:searchResultsComparisonPostcode],
              alsoKnownAs: valid_assessor_request[:alsoKnownAs],
              address: valid_assessor_request[:address],
              companyDetails: valid_assessor_request[:companyDetails],
              qualifications: valid_assessor_request[:qualifications],
              contactDetails: valid_assessor_request[:contactDetails],
            }.to_json,
          )

        expect(assessor_response).to eq(expected_response)
      end
    end

    context "with invalid fields" do
      it "rejects anything that isn't JSON" do
        assertive_put(
          "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
          body: ">>>this is not json<<<",
          accepted_responses: [422],
          should_authenticate: true,
          auth_data: { 'scheme_ids': [scheme_id] },
          scopes: %w[scheme:assessor:update],
        )
      end

      it "rejects an empty request body" do
        assertive_put(
          "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
          body: {},
          accepted_responses: [422],
          should_authenticate: true,
          auth_data: { 'scheme_ids': [scheme_id] },
          scopes: %w[scheme:assessor:update],
        )
      end

      it "rejects requests with invalid assessor ID" do
        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "i_am_a_bad_assessor_id",
          body: valid_assessor_request.dup,
          accepted_responses: [422],
        )
      end

      it "rejects requests without firstname" do
        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "SCHE554433",
          body: assessor_without_key(:firstName),
          accepted_responses: [422],
        )
      end

      it "rejects requests without last name" do
        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "SCHE554433",
          body: assessor_without_key(:lastName),
          accepted_responses: [422],
        )
      end

      it "rejects requests without date of birth" do
        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "SCHE554433",
          body: assessor_without_key(:dateOfBirth),
          accepted_responses: [422],
        )
      end

      it "rejects requests with invalid date of birth" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:dateOfBirth] = "02/28/1987"
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_body, accepted_responses: [422])
      end

      it "rejects requests with invalid first name" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:firstName] = 1_000
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_body, accepted_responses: [422])
      end

      it "rejects requests with invalid last name" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:lastName] = false
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_body, accepted_responses: [422])
      end

      it "rejects requests with invalid middle names" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:middleNames] = %w[adsfasd]
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_body, accepted_responses: [422])
      end

      it "rejects an assessor qualification that isnt a valid status" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:qualifications] = { domesticRdSap: "horse" }
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_body, accepted_responses: [422])
      end

      it "rejects a search results comparison postcode that isnt a string" do
        invalid_body = valid_assessor_request.dup
        invalid_body[:searchResultsComparisonPostcode] = 25
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_body, accepted_responses: [422])
      end
    end

    context "with a clashing ID for an assessor on another scheme" do
      it "Returns a status code 409" do
        first_scheme = add_scheme_and_get_id name: "scheme two"
        second_scheme = add_scheme_and_get_id name: "scheme three"

        add_assessor(scheme_id: first_scheme, assessor_id: "SCHE400111", body: valid_assessor_request)
        add_assessor(scheme_id: second_scheme, assessor_id: "SCHE400111", body: valid_assessor_request, accepted_responses: [409])
      end
    end

    context "with an escaped assessor scheme id" do
      let(:escaped_assessor_scheme_id) { "TEST%2F000000" }

      it "adds an assessor" do
        add_assessor_response =
          add_assessor scheme_id: scheme_id,
                       assessor_id: escaped_assessor_scheme_id,
                       body: valid_assessor_request

        expect(add_assessor_response.status).to eq 201
      end

      it "fetches an assessor" do
        add_assessor scheme_id: scheme_id,
                     assessor_id: escaped_assessor_scheme_id,
                     body: valid_assessor_request

        fetch_assessor_response =
          fetch_assessor(scheme_id: scheme_id, assessor_id: escaped_assessor_scheme_id)

        expect(fetch_assessor_response.status).to eq 200
      end
    end
  end

  context "when updating an assessor" do
    context "with valid fields" do
      it "returns 200 on the update" do
        assessor = valid_assessor_request
        add_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999", body: assessor)
        assessor[:firstName] = "Janine"
        second_response = add_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999", body: assessor)
        expect(second_response.status).to eq(200)
      end

      it "replaces a previous assessors details successfully" do
        assessor = valid_assessor_request
        add_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999", body: assessor)

        assessor[:firstName] = "Janine"
        add_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999", body: assessor)

        response = fetch_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999")

        expected_response = valid_assessor_request
        expected_response[:registeredBy] = {
          schemeId: scheme_id,
          name: "test scheme",
        }
        expected_response[:schemeAssessorId] = "ASSR000999"
        expected_response[:firstName] = "Janine"
        expect(JSON.parse(response.body)["data"]).to eq(
          JSON.parse(expected_response.to_json),
        )
      end
    end

    context "with an invalid email" do
      it "rejects the assessor" do
        invalid_request_body = valid_assessor_request
        invalid_request_body[:contactDetails][:email] = "54"
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: invalid_request_body, accepted_responses: [422])
      end
    end

    context "with a valid email" do
      it "saves it successfully" do
        request_body = valid_assessor_request
        request_body[:contactDetails][:email] = "mar@ten.com"

        add_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999", body: request_body).body

        response_body = fetch_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999").body
        json_response = JSON.parse(response_body)

        expect(json_response["data"]["contactDetails"]["email"]).to eq(
          "mar@ten.com",
        )
      end
    end

    context "with an invalid phone number" do
      it "returns error 400" do
        request_body = valid_assessor_request
        request_body[:contactDetails][:telephoneNumber] = "0" * 257
        add_assessor(scheme_id: scheme_id, assessor_id: "SCHE554433", body: request_body, accepted_responses: [422])
      end
    end

    context "with a valid phone number" do
      it "successfully saves it" do
        valid_telephone = "0" * 256

        request_body = valid_assessor_request
        request_body[:contactDetails][:telephoneNumber] = valid_telephone

        add_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999", body: request_body)

        response_body = fetch_assessor(scheme_id: scheme_id, assessor_id: "ASSR000999").body

        json_response = JSON.parse(response_body)

        expect(
          json_response["data"]["contactDetails"]["telephoneNumber"],
        ).to eq(valid_telephone)
      end
    end
  end
end
