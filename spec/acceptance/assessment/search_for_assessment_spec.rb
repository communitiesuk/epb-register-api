describe "Acceptance::Assessment::SearchForAssessments",
         set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  def setup_scheme_and_lodge(non_domestic: false)
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: AssessorStub.new.fetch_request_body(
        domestic_rd_sap: "ACTIVE",
        non_domestic_nos3: "ACTIVE",
      ),
    )

    if non_domestic
      lodge_assessment(
        assessment_body: Samples.xml("CEPC-8.0.0", "cepc+rr"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    else
      lodge_assessment(
        assessment_body: Samples.xml("RdSAP-Schema-20.0.0"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
    end
    scheme_id
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      domestic_assessments_search_by_assessment_id("123", accepted_responses: [401], should_authenticate: false)
    end

    it "rejects a request without the right scope" do
      domestic_assessments_search_by_assessment_id(
        "123",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      )
    end
  end

  context "when searching by postcode" do
    it "can handle a lowercase postcode" do
      setup_scheme_and_lodge
      response = assessments_search_by_postcode("A00aa")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq 1
    end

    it "can handle a postcode with excessive whitespace" do
      setup_scheme_and_lodge
      response = assessments_search_by_postcode("  A0 0AA    ")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq 1
    end

    it "returns matching assessments" do
      setup_scheme_and_lodge
      response = assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            assessmentId: "0000-0000-0000-0000-0000",
            dateOfAssessment: "2020-05-04",
            dateOfRegistration: "2020-05-04",
            typeOfAssessment: "RdSAP",
            currentEnergyEfficiencyRating: 50,
            currentEnergyEfficiencyBand: "e",
            optOut: false,
            postcode: "A0 0AA",
            dateOfExpiry: "2030-05-03",
            town: "Whitbury",
            addressId: "UPRN-000000000000",
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            status: "ENTERED",
            createdAt: "2021-06-21T00:00:00Z",
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "does not return opted out addresses" do
      setup_scheme_and_lodge
      before_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(before_assessments[:data][:assessments][0]).not_to eq(nil)

      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      after_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(after_assessments[:data][:assessments][0]).to eq(nil)
    end

    it "doesn't show cancelled assessments" do
      scheme_id = setup_scheme_and_lodge
      before_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(before_assessments[:data][:assessments][0]).not_to eq(nil)

      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          "status": "CANCELLED",
        },
        accepted_responses: [200],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      after_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(after_assessments[:data][:assessments][0]).to eq(nil)
    end

    it "doesn't show not for issue assessments" do
      scheme_id = setup_scheme_and_lodge
      before_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(before_assessments[:data][:assessments][0]).not_to eq(nil)

      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          "status": "NOT_FOR_ISSUE",
        },
        accepted_responses: [200],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      after_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(after_assessments[:data][:assessments][0]).to eq(nil)
    end

    it "can filter for commercial results" do
      setup_scheme_and_lodge(non_domestic: true)

      response =
        assessments_search_by_postcode(
          "A0 0AA",
          assessment_types: %w[CEPC],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end

    it "can filter for domestic results" do
      setup_scheme_and_lodge(non_domestic: true)

      response = assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(nil)
    end

    it "rejects a missing postcode" do
      response_body = assessments_search_by_postcode("", accepted_responses: [400]).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "rejects an invalid postcode" do
      response_body = assessments_search_by_postcode("FPV04170EN", accepted_responses: [400]).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            {
              code: "INVALID_REQUEST",
              title: "The requested postcode is not valid",
            },
          ],
        },
      )
    end

    it "rejects an invalid postcode when other arguments are provided" do
      path = "api/assessments/search?postcode=%27&assessment_type%5B%5D=RdSAP&street_name=High+Road&town=Woking&assessment_id=1234-2345-3456-4567-6789"
      response_body = assertive_get(path, accepted_responses: [400], scopes: %w[assessment:search]).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "The requested postcode is not valid" },
          ],
        },
      )
    end

    it "allows missing assessment types" do
      assessments_search_by_postcode "A0 0AA",
                                     assessment_types: []
    end

    it "rejects invalid assessment types" do
      assessments_search_by_postcode "A0 0AA",
                                     accepted_responses: [400],
                                     assessment_types: %w[rdap]
    end

    it "will sort the results" do
      setup_scheme_and_lodge

      second_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
      second_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      second_xml.at("Property Address Address-Line-1").content = "2 Some Street"

      lodge_assessment(
        assessment_body: second_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        assessments_search_by_postcode(
          "A0 0AA",
          assessment_types: %w[RdSAP],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
      expect(response_json[:data][:assessments][1][:assessmentId]).to eq(
        "0000-0000-0000-0000-0001",
      )
    end
  end

  context "when searching by ID" do
    it "returns an error for badly formed IDs" do
      response_body =
        domestic_assessments_search_by_assessment_id(
          "123-123-123-123-123",
          accepted_responses: [400],
        ).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            {
              code: "INVALID_REQUEST",
              title: "The requested assessment id is not valid",
            },
          ],
        },
      )
    end

    it "returns the matching assessment" do
      setup_scheme_and_lodge
      response =
        domestic_assessments_search_by_assessment_id("0000-0000-0000-0000-0000")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            assessmentId: "0000-0000-0000-0000-0000",
            dateOfAssessment: "2020-05-04",
            dateOfRegistration: "2020-05-04",
            typeOfAssessment: "RdSAP",
            currentEnergyEfficiencyRating: 50,
            optOut: false,
            currentEnergyEfficiencyBand: "e",
            postcode: "A0 0AA",
            dateOfExpiry: "2030-05-03",
            town: "Whitbury",
            addressId: "UPRN-000000000000",
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            status: "ENTERED",
            createdAt: "2021-06-21T00:00:00Z",
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end
  end

  context "when searching by town and street name" do
    expected_response =
      JSON.parse(
        {
          assessmentId: "0000-0000-0000-0000-0000",
          dateOfAssessment: "2020-05-04",
          dateOfRegistration: "2020-05-04",
          typeOfAssessment: "RdSAP",
          currentEnergyEfficiencyRating: 50,
          currentEnergyEfficiencyBand: "e",
          optOut: false,
          postcode: "A0 0AA",
          dateOfExpiry: "2030-05-03",
          town: "Whitbury",
          addressId: "UPRN-000000000000",
          addressLine1: "1 Some Street",
          addressLine2: "",
          addressLine3: "",
          addressLine4: "",
          status: "ENTERED",
          createdAt: "2021-06-21T00:00:00Z",
        }.to_json,
      )

    it "rejects a missing town" do
      response_body =
        assessments_search_by_street_name_and_town(street_name: "Palmtree Road", town: "", accepted_responses: [400])
          .body
      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "rejects a missing street name" do
      response_body =
        assessments_search_by_street_name_and_town(street_name: "", town: "Brighton", accepted_responses: [400]).body
      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "allows missing assessment types" do
      assessments_search_by_street_name_and_town street_name: "Palmtree Road",
                                                 town: "Brighton",
                                                 assessment_types: []
    end

    it "returns matching assessments" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town(street_name: "1 Some Street", town: "Whitbury")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with missing property number" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town(street_name: "Some Street", town: "Whitbury")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with missing letters in street" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town(street_name: "ome Street", town: "Whitbury")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "does not return opted out assessments" do
      setup_scheme_and_lodge
      opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")

      response =
        assessments_search_by_street_name_and_town(street_name: "1 Some Street", town: "Whitbury")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq(0)
    end

    it "can filter for commercial assessments" do
      setup_scheme_and_lodge(non_domestic: true)
      response =
        assessments_search_by_street_name_and_town(
          street_name: "2 Lonely Street",
          town: "Whitbury",
          assessment_types: %w[CEPC],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end

    it "will sort the results" do
      setup_scheme_and_lodge

      second_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
      second_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      second_xml.at("Property Address Address-Line-1").content =
        "2a Some Street"

      third_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
      third_xml.at("RRN").content = "0000-0000-0000-0000-0002"
      third_xml.at("Property Address Address-Line-1").content = "3, Some Street"

      lodge_assessment(
        assessment_body: second_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      lodge_assessment(
        assessment_body: third_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      response =
        assessments_search_by_street_name_and_town(street_name: "Some Street", town: "Whitbury")

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(
        response_json[:data][:assessments].map { |a| a[:assessmentId] },
      ).to eq %w[
        0000-0000-0000-0000-0000
        0000-0000-0000-0000-0001
        0000-0000-0000-0000-0002
      ]
    end
  end
end
