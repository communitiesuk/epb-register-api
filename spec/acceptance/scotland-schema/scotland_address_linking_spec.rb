describe "Acceptance::ScotlandAddressLinking", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE")
  end
  let(:valid_scottish_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }
  let(:valid_scottish_dec_xml) { Samples.xml("DECAR-S-7.0", "dec+ar") }
  let(:scheme_id) { add_scheme_and_get_id }

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
                  town,
                  country_code
                )
            VALUES
              (
                '73546792',
                'FK1 1XE',
                '5 Some Place',
                'Cromwell Road',
                '',
                '',
                'Falkirk',
                'S'
              ),
              (
                '73546793',
                'FK1 1XE',
                'The house Some Place',
                'Cromwell Road',
                '',
                '',
                'Falkirk',
                'S'
              ),
              (
                '73546795',
                'FK1 1XE',
                '2 Some Place',
                '345 Cromwell Road',
                '',
                '',
                'Falkirk',
                'S'
              ),
              (
                '736042792',
                'AB24 3FX',
                '5 Cromwell Place',
                'New Road',
                '',
                '',
                'Aberdeen',
                'S'
              )",
    )
    Helper::Toggles.set_feature("register-api-allow-scottish-address-search", true)
  end

  after(:all) do
    Helper::Toggles.set_feature("register-api-allow-scottish-address-search", false)
  end

  context "when the Scottish assessment doesn't exist" do
    it "returns 404" do
      response =
        update_scottish_assessment_address_id(
          assessment_id: "1234-0000-0000-0000-0000",
          new_address_id: "UPRN-000073546793",
          accepted_responses: [404],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "NOT_FOUND", title: "Assessment not found" }],
      )
    end
  end

  context "when the Scottish assessment exists" do
    before do
      add_super_assessor(scheme_id:)

      lodge_scottish_assessment(
        assessment_body: valid_scottish_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end

    it "returns 400 for an addressId in an invalid format" do
      response =
        update_scottish_assessment_address_id(
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
        update_scottish_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-0000-00000000-0000-0",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "RRN is not in the correct format" }],
      )
    end

    it "returns 400 for an UPRN-based addressId with incorrect UPRN format" do
      response =
        update_scottish_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "UPRN-0000735467939999",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "UPRN is not in the correct format" }],
      )
    end

    it "returns 400 for UPRN- identifier that doesn't exist" do
      response =
        update_scottish_assessment_address_id(
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
        update_scottish_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-9999-9999-9999-9999-0000",
          accepted_responses: [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "Address ID does not exist" }],
      )
    end

    it "returns 400 for an invalid response body" do
      response_body = assertive_put(
        "/api/scotland/assessments/0000-0000-0000-0000-0000/address-id",
        body: { "prettyPleaseUpdateAddressIdTo": "bla-bla" },
        accepted_responses: [400],
        scopes: %w[scotland_admin:update-address-id],
      ).body

      error = JSON.parse(response_body, symbolize_names: true)[:errors].first

      expect(error[:code]).to eq("INVALID_REQUEST")
      expect(error[:title]).to include("did not contain a required property of 'addressId'")
    end

    it "returns 400 when body cannot be parsed to JSON" do
      request_body = '{ "addressId": "UPRN-010033533123" " }'
      response = assertive_request(
        accepted_responses: [400],
        should_authenticate: true,
        auth_data: {},
        scopes: %w[scotland_admin:update-address-id],
      ) { put("/api/scotland/assessments/0000-0000-0000-0000-0000/address-id", request_body) }

      error = JSON.parse(response.body, symbolize_names: true)[:errors].first
      expect(error[:code]).to eq("INVALID_REQUEST")
      expect(error[:title]).to include("JSON did not parse. Error: expected ',' or '}'")
    end

    it "changes the address id for to a valid addressId (UPRN- identifier)" do
      update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )

      response =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(response[:data][:addressId]).to eq "UPRN-000073546793"
    end

    it "updates UPRN- identifier to the RRN- identifier that is assessment's own RRN" do
      update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
        accepted_responses: [200],
      )
      response =
        update_scottish_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0000",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
          accepted_responses: [200],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end

    it "shows the assessment as an existing assessment for the new linked address in address search results when searching by address id" do
      update_scottish_assessment_address_id(
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
      update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )
      response =
        JSON.parse(
          address_search_by_postcode("FK1 1XE").body,
          symbolize_names: true,
        )

      expect(
        response[:data][:addresses].find { |address|
          address[:addressId] == "UPRN-000073546793"
        }[
          :existingAssessments,
        ][
          0,
        ][
          :assessmentId,
        ],
      ).to eq "0000-0000-0000-0000-0000"
    end

    it "updates the address updated at column in assessment address id" do
      update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
      )

      response = ActiveRecord::Base.connection.exec_query("SELECT *  FROM scotland.assessments_address_id").first["address_updated_at"]

      expect(response).to eq "2021-06-21 00:00:00 UTC"
    end
  end

  context "when two Scottish assessments exist" do
    before do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)

      lodge_scottish_assessment(
        assessment_body: valid_scottish_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        ensure_uprns: false,
      )

      second_assessment = Nokogiri.XML(valid_scottish_rdsap_xml)
      second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_scottish_assessment(
        assessment_body: second_assessment.to_s,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        ensure_uprns: false,
      )
    end

    it "returns 200 when updating to valid RRN- identifier (assessment with the RRN exists)" do
      response =
        update_scottish_assessment_address_id(
          assessment_id: "0000-0000-0000-0000-0001",
          new_address_id: "RRN-0000-0000-0000-0000-0000",
          accepted_responses: [200],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end

    it "returns 400 with a message that suggests what the addressId should be instead when updating the linked address of an assessment to an RRN- identifier that doesn't match the linked address for that RRN" do
      update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0000",
        new_address_id: "UPRN-000073546793",
        accepted_responses: [200],
      )
      response =
        update_scottish_assessment_address_id(
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

  context "when two Scottish assessments exist but one is cancelled" do
    before do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: AssessorStub.new.fetch_request_body(scotland_rdsap: "ACTIVE"))

      lodge_scottish_assessment(
        assessment_body: valid_scottish_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        ensure_uprns: false,
      )

      second_assessment = Nokogiri.XML(valid_scottish_rdsap_xml)
      second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_scottish_assessment(
        assessment_body: second_assessment.to_s,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        ensure_uprns: false,
      )

      update_scottish_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          status: "CANCELLED",
        },
        auth_data: {
          scheme_ids: [scheme_id],
        },
        accepted_responses: [200],
      )
    end

    it "allows linking to the address ID of the cancelled certificate" do
      response = update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0001",
        new_address_id: "RRN-0000-0000-0000-0000-0000",
        accepted_responses: [200],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end
  end

  context "when updating the Scottish address ID linked to an assessment with a related report" do
    before do
      add_super_assessor(scheme_id:)

      lodge_scottish_assessment(
        assessment_body: valid_scottish_dec_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "DECAR-S-7.0",
        migrated: true,
        ensure_uprns: false,
      )
    end

    it "returns 200 and a success message" do
      response = update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0040",
        new_address_id: "RRN-0000-0000-0000-0000-0050",
        accepted_responses: [200],
      )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end

    it "updates both the records for the requested RRN and its related reports" do
      update_scottish_assessment_address_id(
        assessment_id: "0000-0000-0000-0000-0040",
        new_address_id: "UPRN-000073546793",
      )
      dec_response =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0040").body,
          symbolize_names: true,
        )
      dec_ar_response =
        JSON.parse(
          fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0050").body,
          symbolize_names: true,
        )

      expect(dec_response[:data][:addressId]).to eq("UPRN-000073546793")
      expect(dec_ar_response[:data][:addressId]).to eq("UPRN-000073546793")
    end
  end
end
