describe "Acceptance::Assessment::SearchForAssessments" do
  include RSpecRegisterApiServiceMixin

  def setup_scheme_and_lodge(non_domestic = false)
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id,
      "SPEC000000",
      AssessorStub.new.fetch_request_body(
        domesticRdSap: "ACTIVE", nonDomesticNos3: "ACTIVE",
      ),
    )

    rdsap = File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
    cepc = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc+rr.xml"
    if non_domestic
      lodge_assessment(
        assessment_body: cepc,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    else
      lodge_assessment(
        assessment_body: rdsap,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end
    scheme_id
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

  context "searching by postcode" do
    it "can handle a lowercase postcode" do
      setup_scheme_and_lodge
      response = assessments_search_by_postcode("A00aa")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq 1
    end

    it "can handle a postcode with excessive whitespace" do
      setup_scheme_and_lodge
      response = assessments_search_by_postcode("  A0 0AA    ", [200])

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
            typeOfAssessment: "RdSAP",
            currentEnergyEfficiencyRating: 50,
            currentEnergyEfficiencyBand: "e",
            optOut: false,
            postcode: "A0 0AA",
            dateOfExpiry: "2030-05-04",
            town: "Post-Town1",
            addressId: "UPRN-000000000000",
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            status: "ENTERED",
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

      opt_out_assessment("0000-0000-0000-0000-0000")

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
        assessment_status_body: { "status": "CANCELLED" },
        accepted_responses: [200],
        auth_data: { scheme_ids: [scheme_id] },
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
        assessment_status_body: { "status": "NOT_FOR_ISSUE" },
        accepted_responses: [200],
        auth_data: { scheme_ids: [scheme_id] },
      )

      after_assessments =
        JSON.parse(
          assessments_search_by_postcode("A0 0AA").body,
          symbolize_names: true,
        )

      expect(after_assessments[:data][:assessments][0]).to eq(nil)
    end

    it "can filter for commercial results" do
      setup_scheme_and_lodge(true)

      response =
        assessments_search_by_postcode(
          "A0 0AA",
          [200],
          true,
          nil,
          %w[assessment:search],
          %w[CEPC],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end

    it "can filter for domestic results" do
      setup_scheme_and_lodge(true)

      response = assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(nil)
    end

    it "rejects a missing postcode" do
      response_body = assessments_search_by_postcode("", [400]).body

      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "allows missing assessment types" do
      assessments_search_by_postcode "A0 0AA",
                                     [200],
                                     true,
                                     nil,
                                     %w[assessment:search],
                                     []
    end

    it "rejects invalid assessment types" do
      assessments_search_by_postcode "A0 0AA",
                                     [400],
                                     true,
                                     nil,
                                     %w[assessment:search],
                                     %w[rdap]
    end
  end

  context "searching by ID" do
    it "returns an error for badly formed IDs" do
      response_body =
        domestic_assessments_search_by_assessment_id(
          "123-123-123-123-123",
          [400],
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
            assessor: nil,
            assessmentId: "0000-0000-0000-0000-0000",
            dateOfAssessment: "2020-05-04",
            dateRegistered: "2020-05-04",
            tenure: "1",
            typeOfAssessment: "RdSAP",
            currentEnergyEfficiencyRating: 50,
            potentialEnergyEfficiencyRating: 50,
            currentCarbonEmission: 2.4,
            potentialCarbonEmission: 1.4,
            optOut: false,
            currentEnergyEfficiencyBand: "e",
            potentialEnergyEfficiencyBand: "e",
            postcode: "A0 0AA",
            dateOfExpiry: "2030-05-04",
            town: "Post-Town1",
            addressId: "UPRN-000000000000",
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
            recommendedImprovements: [
              {
                "energyPerformanceRatingImprovement" => 50,
                "environmentalImpactRatingImprovement" => 50,
                "greenDealCategoryCode" => "1",
                "improvementCategory" => "6",
                "improvementCode" => "5",
                "improvementDescription" => nil,
                "improvementTitle" => nil,
                "improvementType" => "Z3",
                "indicativeCost" => "5",
                "sequence" => 0,
                "typicalSaving" => "0.0",
              },
              {
                "energyPerformanceRatingImprovement" => 60,
                "environmentalImpactRatingImprovement" => 64,
                "greenDealCategoryCode" => "3",
                "improvementCategory" => "2",
                "improvementCode" => "1",
                "improvementDescription" => nil,
                "improvementTitle" => nil,
                "improvementType" => "Z2",
                "indicativeCost" => "2",
                "sequence" => 1,
                "typicalSaving" => "0.1",
              },
            ],
            propertyAgeBand: "K",
            status: "ENTERED",
            relatedAssessments: nil,
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end
  end

  context "searching by town and street name" do
    expected_response =
      JSON.parse(
        {
          assessor: nil,
          assessmentId: "0000-0000-0000-0000-0000",
          dateOfAssessment: "2020-05-04",
          dateRegistered: "2020-05-04",
          typeOfAssessment: "RdSAP",
          currentEnergyEfficiencyRating: 50,
          potentialEnergyEfficiencyRating: 50,
          currentCarbonEmission: 2.4,
          potentialCarbonEmission: 1.4,
          currentEnergyEfficiencyBand: "e",
          potentialEnergyEfficiencyBand: "e",
          optOut: false,
          postcode: "A0 0AA",
          dateOfExpiry: "2030-05-04",
          town: "Post-Town1",
          addressId: "UPRN-000000000000",
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
          propertyAgeBand: "K",
          recommendedImprovements: [],
          status: "ENTERED",
          tenure: "1",
          relatedAssessments: nil,
        }.to_json,
      )

    it "rejects a missing town" do
      response_body =
        assessments_search_by_street_name_and_town("Palmtree Road", "", [400])
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
        assessments_search_by_street_name_and_town("", "Brighton", [400]).body
      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            { code: "INVALID_REQUEST", title: "Required query params missing" },
          ],
        },
      )
    end

    it "allows missing assessment types" do
      assessments_search_by_street_name_and_town "Palmtree Road",
                                                 "Brighton",
                                                 [200],
                                                 []
    end

    it "returns matching assessments" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town(
          "1 Some Street",
          "Post-Town1",
        )

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with missing property number" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town("Some Street", "Post-Town1")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with slightly misspelled street" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town("Sum Street", "Post-Town1")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with slightly misspelled town" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town("Some Street", "Post-Twn1")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "returns matching assessments with slightly misspelled street & town" do
      setup_scheme_and_lodge
      response =
        assessments_search_by_street_name_and_town("Sum Street", "Post-Twn1")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "does not return opted out assessments" do
      setup_scheme_and_lodge
      opt_out_assessment("0000-0000-0000-0000-0000")

      response =
        assessments_search_by_street_name_and_town(
          "1 Some Street",
          "Post-Town1",
        )
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq(0)
    end

    it "can filter for commercial assessments" do
      setup_scheme_and_lodge(true)
      response =
        assessments_search_by_street_name_and_town(
          "2 Lonely Street",
          "Post-Town1",
          [200],
          %w[CEPC],
        )
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json[:data][:assessments][0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end
  end
end
