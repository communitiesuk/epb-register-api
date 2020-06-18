describe "Acceptance::Assessment::SearchForDomesticEnergyAssessments" do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticRdSap: "ACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_assessment_body) do
    {
      schemeAssessorId: "TEST123456",
      dateOfAssessment: "2020-01-13",
      dateRegistered: "2020-01-13",
      totalFloorArea: 1_000,
      typeOfAssessment: "RdSAP",
      dwellingType: "Top floor flat",
      currentEnergyEfficiencyRating: 75,
      potentialEnergyEfficiencyRating: 80,
      currentCarbonEmission: 2.4,
      potentialCarbonEmission: 1.4,
      optOut: false,
      postcode: "SE1 7EZ",
      dateOfExpiry: "2021-01-01",
      addressLine1: "Flat 33",
      addressLine2: "18 Palmtree Road",
      addressLine3: "",
      addressLine4: "",
      town: "Brighton",
      heatDemand: {
        currentSpaceHeatingDemand: 222,
        currentWaterHeatingDemand: 321,
        impactOfLoftInsulation: 79,
        impactOfCavityInsulation: 67,
        impactOfSolidWallInsulation: 69,
      },
      recommendedImprovements: [
        {
          sequence: 0,
          improvementCode: "1",
          indicativeCost: "£200 - £4,000",
          typicalSaving: 400.21,
          improvementCategory: "string",
          improvementType: "string",
          energyPerformanceRatingImprovement: 80,
          environmentalImpactRatingImprovement: 90,
          greenDealCategoryCode: "string",
        },
      ],
      propertySummary: [],
      relatedPartyDisclosureText: "string",
    }.freeze
  end

  let(:expected_response) do
    JSON.parse(
      {
        schemeAssessorId: "SPEC000000",
        assessmentId: "0000-0000-0000-0000-0000",
        dateOfAssessment: "2006-05-04",
        dateRegistered: "2006-05-04",
        totalFloorArea: 0.0,
        typeOfAssessment: "RdSAP",
        dwellingType: "Dwelling-Type0",
        currentEnergyEfficiencyRating: 50,
        potentialEnergyEfficiencyRating: 50,
        currentCarbonEmission: 2.4,
        potentialCarbonEmission: 1.4,
        currentEnergyEfficiencyBand: "e",
        potentialEnergyEfficiencyBand: "e",
        optOut: false,
        postcode: "A0 0AA",
        dateOfExpiry: "2016-05-04",
        town: "Post-Town1",
        addressId: nil,
        addressLine1: "1 Some Street",
        addressLine2: "",
        addressLine3: "",
        addressLine4: "",
        heatDemand: {
          currentSpaceHeatingDemand: 30.0,
          currentWaterHeatingDemand: 60.0,
          impactOfLoftInsulation: -8,
          impactOfCavityInsulation: -12,
          impactOfSolidWallInsulation: -16,
        },
        propertySummary: [
          {
            "description" => "Description0",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "wall",
          },
          {
            "description" => "Description1",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "wall",
          },
          {
            "description" => "Description2",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "roof",
          },
          {
            "description" => "Description3",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "roof",
          },
          {
            "description" => "Description4",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "floor",
          },
          {
            "description" => "Description5",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "floor",
          },
          {
            "description" => "Description6",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "window",
          },
          {
            "description" => "Description7",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "main_heating",
          },
          {
            "description" => "Description8",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "main_heating",
          },
          {
            "description" => "Description9",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "main_heating_controls",
          },
          {
            "description" => "Description10",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "main_heating_controls",
          },
          {
            "description" => "Description11",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "hot_water",
          },
          {
            "description" => "Description12",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "lighting",
          },
          {
            "description" => "Description13",
            "energyEfficiencyRating" => 0,
            "environmentalEfficiencyRating" => 0,
            "name" => "secondary_heating",
          },
        ],
        relatedPartyDisclosureNumber: nil,
        relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
      }.to_json,
    )
  end

  let(:valid_assessor_request_body_dom) do
    AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")
  end

  let(:valid_assessor_request_body_non_dom) do
    AssessorStub.new.fetch_request_body(nonDomesticNos3: "ACTIVE")
  end

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end

  let(:valid_cepc_rr_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc+rr.xml"
  end

  context "Security" do
    it "rejects a request without authentication" do
      domestic_assessments_search_by_assessment_id("123", [401], false)
    end

    it "rejects a request without the right scope" do
      domestic_assessments_search_by_assessment_id(
        "123",
        [403],
        true,
        {},
        %w[wrong:scope],
      )
    end
  end

  context "when looking for non-domestic EPCs" do
    it "doesn't show up when searched for by postcode" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_non_dom)

      lodge_assessment(
        assessment_body: valid_cepc_rr_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      response = domestic_assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(nil)
    end
  end

  context "when a search postcode is valid" do
    it "returns status 200 for a get" do
      domestic_assessments_search_by_postcode("SE17EZ", [200])
    end

    it "looks as it should" do
      response = domestic_assessments_search_by_postcode("SE17EZ")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"]).to be_an(Array)
    end

    it "can handle a lowercase postcode" do
      response = domestic_assessments_search_by_postcode("e20sz")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"]).to be_an(Array)
    end

    it "has the properties we expect" do
      response = domestic_assessments_search_by_postcode("SE17EZ")

      response_json = JSON.parse(response.body)

      expect(response_json).to include("data", "meta")
    end

    it "has the over all hash of the shape we expect" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response = domestic_assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            assessmentId: "0000-0000-0000-0000-0000",
            assessor: nil,
            dateOfAssessment: "2006-05-04",
            dateRegistered: "2006-05-04",
            totalFloorArea: 0.0,
            typeOfAssessment: "RdSAP",
            dwellingType: "Dwelling-Type0",
            currentEnergyEfficiencyRating: 50,
            potentialEnergyEfficiencyRating: 50,
            currentCarbonEmission: 2.4,
            potentialCarbonEmission: 1.4,
            currentEnergyEfficiencyBand: "e",
            potentialEnergyEfficiencyBand: "e",
            optOut: false,
            postcode: "A0 0AA",
            dateOfExpiry: "2016-05-04",
            town: "Post-Town1",
            addressId: nil,
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            heatDemand: {
              currentSpaceHeatingDemand: 30.0,
              currentWaterHeatingDemand: 60.0,
              impactOfLoftInsulation: -8,
              impactOfCavityInsulation: -12,
              impactOfSolidWallInsulation: -16,
            },
            propertySummary: [
              {
                "description" => "Description0",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "wall",
              },
              {
                "description" => "Description1",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "wall",
              },
              {
                "description" => "Description2",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "roof",
              },
              {
                "description" => "Description3",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "roof",
              },
              {
                "description" => "Description4",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "floor",
              },
              {
                "description" => "Description5",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "floor",
              },
              {
                "description" => "Description6",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "window",
              },
              {
                "description" => "Description7",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating",
              },
              {
                "description" => "Description8",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating",
              },
              {
                "description" => "Description9",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating_controls",
              },
              {
                "description" => "Description10",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating_controls",
              },
              {
                "description" => "Description11",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "hot_water",
              },
              {
                "description" => "Description12",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "lighting",
              },
              {
                "description" => "Description13",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "secondary_heating",
              },
            ],
            recommendedImprovements: [],
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
            status: "EXPIRED",
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "has been opted out" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response = domestic_assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).not_to eq(nil)

      opt_out_assessment("0000-0000-0000-0000-0000")

      response = domestic_assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(nil)
    end

    it "doesn't show cancelled assessments" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response = domestic_assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).not_to eq(nil)

      response =
        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_status_body: { "status": "CANCELLED" },
          accepted_responses: [200],
          auth_data: { scheme_ids: [scheme_id] },
        )

      response = domestic_assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(nil)
    end
  end

  context "when a search assessment id is valid" do
    it "returns status 200 for a get" do
      domestic_assessments_search_by_assessment_id("123-987", [200])
    end

    it "looks as it should" do
      response = domestic_assessments_search_by_assessment_id("123-987")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"]).to be_an(Array)
    end

    it "has the properties we expect" do
      response = domestic_assessments_search_by_assessment_id("123-987")

      response_json = JSON.parse(response.body)

      expect(response_json).to include("data", "meta")
    end

    it "has the over all hash of the shape we expect" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response =
        domestic_assessments_search_by_assessment_id("0000-0000-0000-0000-0000")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            assessor: nil,
            assessmentId: "0000-0000-0000-0000-0000",
            dateOfAssessment: "2006-05-04",
            dateRegistered: "2006-05-04",
            totalFloorArea: 0.0,
            typeOfAssessment: "RdSAP",
            dwellingType: "Dwelling-Type0",
            currentEnergyEfficiencyRating: 50,
            potentialEnergyEfficiencyRating: 50,
            currentCarbonEmission: 2.4,
            potentialCarbonEmission: 1.4,
            optOut: false,
            currentEnergyEfficiencyBand: "e",
            potentialEnergyEfficiencyBand: "e",
            postcode: "A0 0AA",
            dateOfExpiry: "2016-05-04",
            town: "Post-Town1",
            addressId: nil,
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            heatDemand: {
              currentSpaceHeatingDemand: 30.0,
              currentWaterHeatingDemand: 60.0,
              impactOfLoftInsulation: -8,
              impactOfCavityInsulation: -12,
              impactOfSolidWallInsulation: -16,
            },
            propertySummary: [
              {
                "description" => "Description0",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "wall",
              },
              {
                "description" => "Description1",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "wall",
              },
              {
                "description" => "Description2",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "roof",
              },
              {
                "description" => "Description3",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "roof",
              },
              {
                "description" => "Description4",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "floor",
              },
              {
                "description" => "Description5",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "floor",
              },
              {
                "description" => "Description6",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "window",
              },
              {
                "description" => "Description7",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating",
              },
              {
                "description" => "Description8",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating",
              },
              {
                "description" => "Description9",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating_controls",
              },
              {
                "description" => "Description10",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "main_heating_controls",
              },
              {
                "description" => "Description11",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "hot_water",
              },
              {
                "description" => "Description12",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "lighting",
              },
              {
                "description" => "Description13",
                "energyEfficiencyRating" => 0,
                "environmentalEfficiencyRating" => 0,
                "name" => "secondary_heating",
              },
            ],
            recommendedImprovements: [],
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
            status: "EXPIRED",
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end
  end

  context "when using town and street name" do
    context "and town is missing but street name is present" do
      it "returns status 400 for a get" do
        domestic_assessments_search_by_street_name_and_town(
          "Palmtree Road",
          "",
          [400],
        )
      end

      it "contains the correct error message" do
        response_body =
          domestic_assessments_search_by_street_name_and_town(
            "Palmtree Road",
            "",
            [400],
          )
            .body
        expect(JSON.parse(response_body)).to eq(
          {
            "errors" => [
              {
                "code" => "MALFORMED_REQUEST",
                "title" => "Required query params missing",
              },
            ],
          },
        )
      end
    end

    context "and street name is missing but town is present" do
      it "returns status 400 for a get" do
        domestic_assessments_search_by_street_name_and_town(
          "",
          "Brighton",
          [400],
        )
      end

      it "contains the correct error message" do
        response_body =
          domestic_assessments_search_by_street_name_and_town(
            "",
            "Brighton",
            [400],
          )
            .body
        expect(JSON.parse(response_body)).to eq(
          {
            "errors" => [
              {
                "code" => "MALFORMED_REQUEST",
                "title" => "Required query params missing",
              },
            ],
          },
        )
      end
    end

    context "and required parameters are present" do
      it "returns status 200 for a get" do
        domestic_assessments_search_by_street_name_and_town(
          "Palmtree Road",
          "Brighton",
          [200],
        )
      end

      it "looks as it should" do
        response =
          domestic_assessments_search_by_street_name_and_town(
            "Palmtree Road",
            "Brighton",
          )

        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessments"]).to be_an(Array)
      end

      it "has the properties we expect" do
        response =
          domestic_assessments_search_by_street_name_and_town(
            "Palmtree Road",
            "Brighton",
          )

        response_json = JSON.parse(response.body)

        expect(response_json).to include("data", "meta")
      end

      it "has the over all hash of the shape we expect" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

        lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
        )

        response =
          domestic_assessments_search_by_street_name_and_town(
            "1 Some Street",
            "Post-Town1",
          )

        response_json = JSON.parse(response.body)

        expected_response =
          JSON.parse(
            {
              assessor: nil,
              assessmentId: "0000-0000-0000-0000-0000",
              dateOfAssessment: "2006-05-04",
              dateRegistered: "2006-05-04",
              totalFloorArea: 0.0,
              typeOfAssessment: "RdSAP",
              dwellingType: "Dwelling-Type0",
              currentEnergyEfficiencyRating: 50,
              potentialEnergyEfficiencyRating: 50,
              currentCarbonEmission: 2.4,
              potentialCarbonEmission: 1.4,
              currentEnergyEfficiencyBand: "e",
              potentialEnergyEfficiencyBand: "e",
              optOut: false,
              postcode: "A0 0AA",
              dateOfExpiry: "2016-05-04",
              town: "Post-Town1",
              addressId: nil,
              addressLine1: "1 Some Street",
              addressLine2: "",
              addressLine3: "",
              addressLine4: "",
              heatDemand: {
                currentSpaceHeatingDemand: 30.0,
                currentWaterHeatingDemand: 60.0,
                impactOfLoftInsulation: -8,
                impactOfCavityInsulation: -12,
                impactOfSolidWallInsulation: -16,
              },
              propertySummary: [
                {
                  "description" => "Description0",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "wall",
                },
                {
                  "description" => "Description1",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "wall",
                },
                {
                  "description" => "Description2",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "roof",
                },
                {
                  "description" => "Description3",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "roof",
                },
                {
                  "description" => "Description4",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "floor",
                },
                {
                  "description" => "Description5",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "floor",
                },
                {
                  "description" => "Description6",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "window",
                },
                {
                  "description" => "Description7",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "main_heating",
                },
                {
                  "description" => "Description8",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "main_heating",
                },
                {
                  "description" => "Description9",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "main_heating_controls",
                },
                {
                  "description" => "Description10",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "main_heating_controls",
                },
                {
                  "description" => "Description11",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "hot_water",
                },
                {
                  "description" => "Description12",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "lighting",
                },
                {
                  "description" => "Description13",
                  "energyEfficiencyRating" => 0,
                  "environmentalEfficiencyRating" => 0,
                  "name" => "secondary_heating",
                },
              ],
              recommendedImprovements: [],
              relatedPartyDisclosureNumber: nil,
              relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
              status: "EXPIRED",
            }.to_json,
          )

        expect(response_json["data"]["assessments"][0]).to eq(expected_response)
      end

      it "has been opted out" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

        lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
        )

        opt_out_assessment("0000-0000-0000-0000-0000")

        response =
          domestic_assessments_search_by_street_name_and_town(
            "1 Some Street",
            "Post-Town1",
          )
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessments"].length).to eq(0)
      end
    end
  end
end
