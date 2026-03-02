describe "Acceptance::Assessment::ScotlandSearchForAssessments", :set_with_timecop do
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
        assessment_body: Samples.xml("CEPC-S-7.1", "cepc"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-S-7.1",
        migrated: true,
      )
    else
      lodge_assessment(
        assessment_body: Samples.xml("RdSAP-Schema-S-19.0"),
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: true,
      )
    end
    scheme_id
  end

  describe "security scenarios" do
    it "rejects a request without authentication" do
      expect(scottish_domestic_assessments_search_by_assessment_id("123", accepted_responses: [401], should_authenticate: false).status).to eq(401)
    end

    it "rejects a request without the right scope" do
      expect(scottish_domestic_assessments_search_by_assessment_id(
        "123",
        accepted_responses: [403],
        scopes: %w[wrong:scope],
      ).status).to eq(403)
    end
  end

  context "when searching by postcode" do
    it "can handle a lowercase postcode" do
      setup_scheme_and_lodge
      response = scottish_assessments_search_by_postcode("fk11xe")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq 1
    end

    it "can handle a postcode with excessive whitespace" do
      setup_scheme_and_lodge
      response = scottish_assessments_search_by_postcode("  fk1   1xe    ")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq 1
    end

    it "returns matching assessments" do
      setup_scheme_and_lodge
      response = scottish_assessments_search_by_postcode("FK1 1XE")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            dateOfAssessment: "2023-06-27",
            dateOfExpiry: "2033-06-26",
            dateOfRegistration: "2023-06-27",
            typeOfAssessment: "RdSAP",
            assessmentId: "0000-0000-0000-0000-0000",
            currentEnergyEfficiencyRating: 79,
            currentEnergyEfficiencyBand: "c",
            optOut: false,
            addressId: "RRN-0000-0000-0000-0000-0000",
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            town: "Newkirk",
            postcode: "FK1 1XE",
            status: "ENTERED",
            createdAt: "2021-06-21T00:00:00Z",
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    # TODO: Update when assessment opt-out done for Scotland
    # it "does not return opted out addresses" do
    #   setup_scheme_and_lodge
    #   before_assessments =
    #     JSON.parse(
    #       scottish_assessments_search_by_postcode("FK1 1XE").body,
    #       symbolize_names: true,
    #     )
    #
    #   expect(before_assessments[:data][:assessments][0]).not_to be_nil
    #
    #   opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
    #
    #   after_assessments =
    #     JSON.parse(
    #       assessments_search_by_postcode("FK1 1XE").body,
    #       symbolize_names: true,
    #     )
    #
    #   expect(after_assessments[:data][:assessments][0]).to be_nil
    # end
    # TODO Update when assessment status update has been done for Scotland
    # it "doesn't show cancelled assessments" do
    #   scheme_id = setup_scheme_and_lodge
    #   before_assessments =
    #     JSON.parse(
    #       scottish_assessments_search_by_postcode("FK1 1XE").body,
    #       symbolize_names: true,
    #     )
    #
    #   expect(before_assessments[:data][:assessments][0]).not_to be_nil
    #
    #   update_assessment_status(
    #     assessment_id: "0000-0000-0000-0000-0000",
    #     assessment_status_body: {
    #       "status": "CANCELLED",
    #     },
    #     accepted_responses: [200],
    #     auth_data: {
    #       scheme_ids: [scheme_id],
    #     },
    #   )
    #
    #   after_assessments =
    #     JSON.parse(
    #       scottish_assessments_search_by_postcode("FK1 1XE").body,
    #       symbolize_names: true,
    #     )
    #
    #   expect(after_assessments[:data][:assessments][0]).to be_nil
    # end
    # TODO Update when assessment status update has been done for Scotland
    # it "doesn't show not for issue assessments" do
    #   scheme_id = setup_scheme_and_lodge
    #   before_assessments =
    #     JSON.parse(
    #       assessments_search_by_postcode("SW1A 2AA").body,
    #       symbolize_names: true,
    #     )
    #
    #   expect(before_assessments[:data][:assessments][0]).not_to be_nil
    #
    #   update_assessment_status(
    #     assessment_id: "0000-0000-0000-0000-0000",
    #     assessment_status_body: {
    #       "status": "NOT_FOR_ISSUE",
    #     },
    #     accepted_responses: [200],
    #     auth_data: {
    #       scheme_ids: [scheme_id],
    #     },
    #   )
    #
    #   after_assessments =
    #     JSON.parse(
    #       assessments_search_by_postcode("SW1A 2AA").body,
    #       symbolize_names: true,
    #     )
    #
    #   expect(after_assessments[:data][:assessments][0]).to be_nil
    # end

    it "can filter for non-domestic results" do
      setup_scheme_and_lodge(non_domestic: true)

      response =
        scottish_assessments_search_by_postcode(
          "FK1 1XE",
          assessment_types: %w[CEPC],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end

    it "can filter for domestic results" do
      setup_scheme_and_lodge(non_domestic: true)

      response = scottish_assessments_search_by_postcode("FK1 1XE")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to be_nil
    end

    it "rejects a missing postcode" do
      response_body = scottish_assessments_search_by_postcode("", accepted_responses: [400]).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "rejects an invalid postcode" do
      response_body = scottish_assessments_search_by_postcode("FPV04170EN", accepted_responses: [400]).body

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
      path = "api/scotland/assessments/search?postcode=%27&assessment_type%5B%5D=RdSAP&street_name=High+Road&town=Woking&assessment_id=1234-2345-3456-4567-6789"
      response_body = assertive_get(path, accepted_responses: [400], scopes: %w[scotland_assessment:search]).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "The requested postcode is not valid" },
          ],
        },
      )
    end

    it "allows missing assessment types" do
      expect(scottish_assessments_search_by_postcode("FK1 1XE", assessment_types: []).status).to eq 200
    end

    it "rejects invalid assessment types" do
      expect(scottish_assessments_search_by_postcode("FK1 1XE",
                                                     accepted_responses: [400],
                                                     assessment_types: %w[rdap]).status).to eq 400
    end

    it "sorts the results" do
      setup_scheme_and_lodge

      second_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-S-19.0"))
      second_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      second_xml.at("Property Address Address-Line-1").content = "9 Some Street"

      lodge_assessment(
        assessment_body: second_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: true,
      )

      response =
        scottish_assessments_search_by_postcode(
          "FK1 1XE",
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
        scottish_domestic_assessments_search_by_assessment_id("0000-0000-0000-0000-0000")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            assessmentId: "0000-0000-0000-0000-0000",
            dateOfAssessment: "2023-06-27",
            dateOfRegistration: "2023-06-27",
            typeOfAssessment: "RdSAP",
            currentEnergyEfficiencyRating: 79,
            optOut: false,
            currentEnergyEfficiencyBand: "c",
            postcode: "FK1 1XE",
            dateOfExpiry: "2033-06-26",
            town: "Newkirk",
            addressId: "RRN-0000-0000-0000-0000-0000",
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
          dateOfAssessment: "2023-06-27",
          dateOfRegistration: "2023-06-27",
          typeOfAssessment: "RdSAP",
          currentEnergyEfficiencyRating: 79,
          currentEnergyEfficiencyBand: "c",
          optOut: false,
          postcode: "FK1 1XE",
          dateOfExpiry: "2033-06-26",
          town: "Newkirk",
          addressId: "RRN-0000-0000-0000-0000-0000",
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
        scottish_assessments_search_by_street_and_town(street: "Palmtree Road", town: "", accepted_responses: [400])
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
        scottish_assessments_search_by_street_and_town(street: "", town: "Newkirk", accepted_responses: [400]).body
      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "allows missing assessment types" do
      expect(scottish_assessments_search_by_street_and_town(street: "Some street",
                                                            town: "Newkirk",
                                                            assessment_types: []).status).to eq(200)
    end

    it "returns matching assessments" do
      setup_scheme_and_lodge
      response =
        scottish_assessments_search_by_street_and_town(street: "1 Some Street", town: "Newkirk")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with missing property number" do
      setup_scheme_and_lodge
      response =
        scottish_assessments_search_by_street_and_town(street: "Some Street", town: "Newkirk")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with missing letters in street" do
      setup_scheme_and_lodge
      response =
        scottish_assessments_search_by_street_and_town(street: "ome Street", town: "Newkirk")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    # TODO: Update when assessment opt-out done for Scotland
    # it "does not return opted out assessments" do
    #   setup_scheme_and_lodge
    #   opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
    #
    #   response =
    #     assessments_search_by_street_and_town(street: "1 Some Street", town: "Whitbury")
    #   response_json = JSON.parse(response.body)
    #
    #   expect(response_json["data"]["assessments"].length).to eq(0)
    # end

    it "can filter for non-domestic assessments" do
      setup_scheme_and_lodge(non_domestic: true)
      response =
        scottish_assessments_search_by_street_and_town(
          street: "Some Street",
          town: "Town",
          assessment_types: %w[CEPC],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end

    it "sorts the results" do
      setup_scheme_and_lodge

      second_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-S-19.0"))
      second_xml.at("RRN").content = "0000-0000-0000-0000-0001"
      second_xml.at("Property Address Address-Line-1").content =
        "2a Some Street"

      third_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-S-19.0"))
      third_xml.at("RRN").content = "0000-0000-0000-0000-0002"
      third_xml.at("Property Address Address-Line-1").content = "3, Some Street"

      lodge_assessment(
        assessment_body: second_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: true,
      )

      lodge_assessment(
        assessment_body: third_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: true,
      )

      response =
        scottish_assessments_search_by_street_and_town(street: "Some Street", town: "Newkirk")

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(
        response_json[:data][:assessments].map { |a| a[:assessmentId] },
      ).to eq %w[
        0000-0000-0000-0000-0000
        0000-0000-0000-0000-0001
        0000-0000-0000-0000-0002
      ]
    end

    context "when the number results are greater than 200" do
      let(:find_use_case) { instance_double(UseCase::FindAssessmentsByStreetNameAndTown) }
      let(:gateway) { instance_double(Gateway::AssessmentsSearchGateway) }

      before do
        allow(ApiFactory).to receive(:find_assessments_by_street_name_and_town).and_return(
          find_use_case,
        )
        allow(Gateway::AssessmentsSearchGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:search_by_street_name_and_town).and_return({ data: [] })
        allow(find_use_case).to receive(:execute).and_raise Boundary::TooManyResults
      end

      it "raises the error" do
        response_body =
          scottish_assessments_search_by_street_and_town(street: "Some Street", town: "Newkirk", accepted_responses: [413])
            .body
        expect(JSON.parse(response_body, symbolize_names: true)).to eq(
          {
            errors: [
              {
                code: "PAYLOAD_TOO_LARGE",
                title: "There are too many results",
              },
            ],
          },
        )
      end
    end
  end
end
