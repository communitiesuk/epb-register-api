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
      add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

      commercial_assessment = valid_assessment_body.dup
      commercial_assessment[:typeOfAssessment] = "CEPC"
      migrate_assessment("123-987", commercial_assessment)

      response = domestic_assessments_search_by_postcode("SE17EZ")
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
      add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)
      migrate_assessment("123-987", valid_assessment_body)

      response = domestic_assessments_search_by_postcode("SE17EZ")
      response_json = JSON.parse(response.body)

      expected_response =
        JSON.parse(
          {
            schemeAssessorId: "TEST123456",
            assessmentId: "123-987",
            dateOfAssessment: "2020-01-13",
            dateRegistered: "2020-01-13",
            totalFloorArea: 1_000.0,
            typeOfAssessment: "RdSAP",
            dwellingType: "Top floor flat",
            currentEnergyEfficiencyRating: 75,
            potentialEnergyEfficiencyRating: 80,
            currentCarbonEmission: 2.4,
            potentialCarbonEmission: 1.4,
            currentEnergyEfficiencyBand: "c",
            potentialEnergyEfficiencyBand: "c",
            optOut: false,
            postcode: "SE1 7EZ",
            dateOfExpiry: "2021-01-01",
            town: "Brighton",
            addressLine1: "Flat 33",
            addressLine2: "18 Palmtree Road",
            addressLine3: "",
            addressLine4: "",
            heatDemand: {
              currentSpaceHeatingDemand: 222.0,
              currentWaterHeatingDemand: 321.0,
              impactOfLoftInsulation: 79,
              impactOfCavityInsulation: 67,
              impactOfSolidWallInsulation: 69,
            },
            propertySummary: [],
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "string",
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "has been opted out" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

      opted_out_assessment = valid_assessment_body.dup
      opted_out_assessment[:optOut] = true
      migrate_assessment("123-987", opted_out_assessment)

      response = domestic_assessments_search_by_postcode("SE17EZ")
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
      add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)
      migrate_assessment("123-987", valid_assessment_body)
      response = domestic_assessments_search_by_assessment_id("123-987")

      response_json = JSON.parse(response.body)

      expected_response =
        JSON.parse(
          {
            schemeAssessorId: "TEST123456",
            assessmentId: "123-987",
            dateOfAssessment: "2020-01-13",
            dateRegistered: "2020-01-13",
            totalFloorArea: 1_000.0,
            typeOfAssessment: "RdSAP",
            dwellingType: "Top floor flat",
            currentEnergyEfficiencyRating: 75,
            potentialEnergyEfficiencyRating: 80,
            currentCarbonEmission: 2.4,
            potentialCarbonEmission: 1.4,
            optOut: false,
            currentEnergyEfficiencyBand: "c",
            potentialEnergyEfficiencyBand: "c",
            postcode: "SE1 7EZ",
            dateOfExpiry: "2021-01-01",
            town: "Brighton",
            addressLine1: "Flat 33",
            addressLine2: "18 Palmtree Road",
            addressLine3: "",
            addressLine4: "",
            heatDemand: {
              currentSpaceHeatingDemand: 222.0,
              currentWaterHeatingDemand: 321.0,
              impactOfLoftInsulation: 79,
              impactOfCavityInsulation: 67,
              impactOfSolidWallInsulation: 69,
            },
            propertySummary: [],
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "string",
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
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

        migrate_assessment("123-987", valid_assessment_body)
        response =
          domestic_assessments_search_by_street_name_and_town(
            "Palmtree Road",
            "Brighton",
          )

        response_json = JSON.parse(response.body)

        expected_response =
          JSON.parse(
            {
              schemeAssessorId: "TEST123456",
              assessmentId: "123-987",
              dateOfAssessment: "2020-01-13",
              dateRegistered: "2020-01-13",
              totalFloorArea: 1_000.0,
              typeOfAssessment: "RdSAP",
              dwellingType: "Top floor flat",
              currentEnergyEfficiencyRating: 75,
              potentialEnergyEfficiencyRating: 80,
              currentCarbonEmission: 2.4,
              potentialCarbonEmission: 1.4,
              currentEnergyEfficiencyBand: "c",
              potentialEnergyEfficiencyBand: "c",
              optOut: false,
              postcode: "SE1 7EZ",
              dateOfExpiry: "2021-01-01",
              town: "Brighton",
              addressLine1: "Flat 33",
              addressLine2: "18 Palmtree Road",
              addressLine3: "",
              addressLine4: "",
              heatDemand: {
                currentSpaceHeatingDemand: 222.0,
                currentWaterHeatingDemand: 321.0,
                impactOfLoftInsulation: 79,
                impactOfCavityInsulation: 67,
                impactOfSolidWallInsulation: 69,
              },
              propertySummary: [],
              relatedPartyDisclosureNumber: nil,
              relatedPartyDisclosureText: "string",
            }.to_json,
          )

        expect(response_json["data"]["assessments"][0]).to eq(expected_response)
      end

      it "has been opted out" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

        opted_out_assessment = valid_assessment_body.dup
        opted_out_assessment[:optOut] = true
        migrate_assessment("123-987", opted_out_assessment)

        response =
          domestic_assessments_search_by_street_name_and_town(
            "Palmtree Road",
            "Brighton",
          )
        response_json = JSON.parse(response.body)

        expect(response_json["data"]["assessments"][0]).to be_nil
      end
    end
  end
end
