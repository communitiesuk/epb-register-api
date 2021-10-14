describe "Acceptance::AddressLinking", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    ActiveRecord::Base.connection.exec_query(
      "INSERT INTO
              address_base
                (
                  uprn,
                  postcode,
                  address_line1,
                  address_line2,
                  address_line3,
                  address_line4,
                  town
                )
            VALUES
              (
                '73546792',
                'A0 0AA',
                '5 Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546793',
                'A0 0AA',
                'The house Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546795',
                'A0 0AA',
                '2 Grimal Place',
                '345 Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '736042792',
                'NE23 1TW',
                '5 Grimiss Place',
                'Suggton Road',
                '',
                '',
                'Newcastle'
              )",
    )
  end

  context "when assessment doesn't exist" do
    it "returns 404" do
      response =
        update_assessment_address_id(
          assessment_id: "1234-0000-0000-0000-0000",
          new_address_id: "UPRN-000073546793",
          accepted_responses: [404],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "NOT_FOUND", title: "Assessment not found" }],
      )
    end
  end

  context "when assessment exists" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

      lodge_assessment(
        assessment_body: Samples.xml("RdSAP-Schema-20.0.0"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
    end

    it "returns 400 for an addressId in an invalid format" do
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "MY-PRETTY-HOUSE",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "AddressId has to begin with UPRN- or RRN-" }],
      )
    end

    it "returns 400 for an RRN-based addressId with incorrect RRN format" do
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-0000-00000000-0000-0",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "RRN number is not in the correct format" }],
      )
    end

    it "returns 400 for UPRN- identifier that doesn't exist" do
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "UPRN-999912399999",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "Address ID does not exist" }],
      )
    end

    it "returns 400 for RRN- identifier that doesn't exist" do
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-9999-9999-9999-9999-0000",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "Address ID does not exist" }],
      )
    end

    it "returns 422 for an invalid response body" do
      response_body = assertive_put(
        "/api/assessments/0000-0000-0000-0000-0000/address-id",
        body: { "prettyPleaseUpdateAddressIdTo": "bla-bla" },
        accepted_responses: [422],
        scopes: %w[admin:update-address-id],
      ).body

      error = JSON.parse(response_body, symbolize_names: true)[:errors].first

      expect(error[:code]).to eq("INVALID_REQUEST")
      expect(error[:title]).to include("did not contain a required property of 'addressId'")
    end

    it "changes the address id for to a valid addressId (UPRN- identifier)" do
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )

      response =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(response[:data][:addressId]).to eq "UPRN-000073546793"
    end

    it "updates UPRN- identifier to the RRN- identifier that is assessment's own RRN" do
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
        accepted_responses: [200],
      )
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
          accepted_responses: [200],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end

    it "shows the assessment as an existing assessment for the new linked address in address search results when searching by address id" do
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )

      response =
        JSON.parse(
          address_search_by_id("UPRN-000073546793").body,
          symbolize_names: true,
        )

      expect(
        response[:data][:addresses][0][:existingAssessments][0][:assessmentId],
      ).to eq "0000-0000-0000-0000-0000"
    end

    it "shows the assessment as an existing assessment for the new linked address in address search results when searching by postcode" do
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )
      response =
        JSON.parse(
          address_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(
        response[:data][:addresses].find { |address|
          address[:addressId] == "UPRN-000073546793"
        }[
          :existingAssessments
        ][
          0
        ][
          :assessmentId
        ],
      ).to eq "0000-0000-0000-0000-0000"
    end
  end

  context "when two assessments exist" do
    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id: scheme_id, assessor_id: "SPEC000000", body: AssessorStub.new.fetch_request_body(domestic_rd_sap: "ACTIVE"))

      lodge_assessment(
        assessment_body: Samples.xml("RdSAP-Schema-20.0.0"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      second_assessment = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
      second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: second_assessment.to_s,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )
    end

    it "returns 200 when updating to valid RRN- identifier (assessment with the RRN exists)" do
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0001",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
          accepted_responses: [200],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end

    it "returns 400 with a message that suggests what the addressId should be instead when updating the linked address of an assessment to an RRN- identifier that doesn't match the linked address for that RRN" do
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
        accepted_responses: [200],
      )
      response =
        update_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0001",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [
          {
            code: "BAD_REQUEST",
            title:
              "Address ID mismatched: Assessment 0000-0000-0000-0000-0000 is linked to address ID UPRN-000073546793",
          },
        ],
      )
    end
  end

  context "when updating the address ID linked to an assessment with a related report" do
    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id: scheme_id, assessor_id: "SPEC000000", body: AssessorStub.new.fetch_request_body(non_domestic_nos3: "ACTIVE"))

      lodge_assessment(
        assessment_body: Samples.xml("CEPC-8.0.0", "cepc+rr"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        ensure_uprns: false,
      )
    end

    it "returns 200 and a success message" do
      response = update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "RRN-0000-0000-0000-0000-0001",
        accepted_responses: [200],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end

    it "updates both the records for the requested RRN and its related reports" do
      update_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )
      cepc_response =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      cepc_rr_response =
        JSON.parse(
          fetch_assessment_summary(id: "0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )

      expect(cepc_response[:data][:addressId]).to eq("UPRN-000073546793")
      expect(cepc_rr_response[:data][:addressId]).to eq("UPRN-000073546793")
    end
  end
end
