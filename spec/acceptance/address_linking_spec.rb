describe "Acceptance::AddressLinking", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domesticRdSap: "ACTIVE",
      nonDomesticNos3: "ACTIVE",
      nonDomesticNos4: "ACTIVE",
      nonDomesticNos5: "ACTIVE",
    )
  end
  let(:rdsap_xml) { Samples.xml("RdSAP-Schema-20.0.0") }
  let(:non_domestic_xml) { Samples.xml("CEPC-8.0.0", "cepc+rr") }

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

  context "when updating the linked address of an assessment that doesnt exist" do
    it "returns 404" do
      response =
        update_assessment_address_id(
          "0000-0000-0000-0000-0000",
          "UPRN-000073546793",
          [404],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "NOT_FOUND", title: "Assessment not found" }],
      )
    end
  end

  context "when updating the linked address of an assessment to a UPRN- identifier that doesn't exist" do
    it "returns 400" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        update_assessment_address_id(
          "0000-0000-0000-0000-0000",
          "UPRN-999999999999",
          [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "Address ID does not exist" }],
      )
    end
  end

  context "when updating the linked address of an assessment to an RRN- identifier that doesn't exist" do
    it "returns 400" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        update_assessment_address_id(
          "0000-0000-0000-0000-0000",
          "RRN-9999-9999-9999-9999-9999",
          [400],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
        [{ code: "BAD_REQUEST", title: "Address ID does not exist" }],
      )
    end
  end

  context "when updating the address ID linked to an assessment to a UPRN that exists" do
    it "changes the address id returned in the assessment summary JSON" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000", [200]).body,
          symbolize_names: true,
        )

      expect(response[:data][:addressId]).to eq "UPRN-000000000000"

      update_assessment_address_id(
        "0000-0000-0000-0000-0000",
        "UPRN-000073546793",
      )

      response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000", [200]).body,
          symbolize_names: true,
        )

      expect(response[:data][:addressId]).to eq "UPRN-000073546793"
    end

    it "shows the assessment as an existing assessment for the new linked address in address search results when searching by address id" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      update_assessment_address_id(
        "0000-0000-0000-0000-0000",
        "UPRN-000073546793",
      )

      response =
        JSON.parse(
          address_search_by_id("UPRN-000073546793", [200]).body,
          symbolize_names: true,
        )

      expect(
        response[:data][:addresses][0][:existingAssessments][0][:assessmentId],
      ).to eq "0000-0000-0000-0000-0000"
    end

    it "shows the assessment as an existing assessment for the new linked address in address search results when searching by postcode" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      update_assessment_address_id(
        "0000-0000-0000-0000-0000",
        "UPRN-000073546793",
      )

      response =
        JSON.parse(
          address_search_by_postcode("A0 0AA", [200]).body,
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

  context "when updating the linked address of an assessment to an RRN- identifier that exists" do
    it "returns 200 and a success message" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      second_assessment = Nokogiri.XML rdsap_xml
      second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: second_assessment.to_s,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      response =
        update_assessment_address_id(
          "0000-0000-0000-0000-0001",
          "UPRN-000000000000",
          [200],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end
  end

  context "when updating the linked address of an assessment to an RRN- identifier that doesn't match the linked address for that RRN" do
    it "returns 400 with a message that suggests what the addressId should be instead" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      second_assessment = Nokogiri.XML rdsap_xml
      second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: second_assessment.to_s,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
      )

      update_assessment_address_id(
        "0000-0000-0000-0000-0000",
        "UPRN-000073546793",
        [200],
      )
      response =
        update_assessment_address_id(
          "0000-0000-0000-0000-0001",
          "RRN-0000-0000-0000-0000-0000",
          [400],
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

  context "when updating the linked address of an assessment to an RRN- identifier that is its own RRN" do
    it "returns 200 and a success message even if the address_id is currently different" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      update_assessment_address_id(
        "0000-0000-0000-0000-0000",
        "UPRN-000073546793",
        [200],
      )
      response =
        update_assessment_address_id(
          "0000-0000-0000-0000-0000",
          "RRN-0000-0000-0000-0000-0000",
          [200],
        )
      expect(JSON.parse(response.body, symbolize_names: true)[:data]).to eq(
        "Address ID has been updated",
      )
    end
  end

  context "when updating the address ID linked to an assessment with a related report" do
    it "updates both the records for the requested RRN and its related reports" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: non_domestic_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      cepc_response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000", [200]).body,
          symbolize_names: true,
        )
      cepc_rr_response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001", [200]).body,
          symbolize_names: true,
        )

      expected_address_id = "UPRN-000000000001"

      expect(
        cepc_response[:data][:addressId],
      ).to eq expected_address_id
      expect(
        cepc_rr_response[:data][:addressId],
      ).to eq expected_address_id

      update_assessment_address_id(
        "0000-0000-0000-0000-0000",
        "UPRN-000073546793",
      )

      cepc_response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000", [200]).body,
          symbolize_names: true,
        )
      cepc_rr_response =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001", [200]).body,
          symbolize_names: true,
        )
      expect(cepc_response[:data][:addressId]).to eq "UPRN-000073546793"
      expect(cepc_rr_response[:data][:addressId]).to eq "UPRN-000073546793"
    end
  end
end
