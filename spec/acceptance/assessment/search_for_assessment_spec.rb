describe "Acceptance::Assessment::SearchForAssessments" do
  include RSpecRegisterApiServiceMixin

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

  context "searching by postcode" do
    it "can handle a lowercase postcode" do
      response = assessments_search_by_postcode("e20sz")

      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"]).to be_an(Array)
    end

    it "returns matching assessments" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response = assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)
      expected_response =
        JSON.parse(
          {
            assessmentId: "0000-0000-0000-0000-0000",
            assessor: nil,
            dateOfAssessment: "2020-05-04",
            dateRegistered: "2020-05-04",
            tenure: "1",
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
            dateOfExpiry: "2030-05-04",
            town: "Post-Town1",
            addressId: nil,
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            lightingCostCurrent: "123.45",
            heatingCostCurrent: "365.98",
            hotWaterCostCurrent: "200.40",
            lightingCostPotential: "84.23",
            heatingCostPotential: "250.34",
            hotWaterCostPotential: "180.43",
            estimatedEnergyCost: "689.83",
            potentialEnergySaving: "174.83",
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
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
            status: "ENTERED",
            relatedAssessments: nil,
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "does not return opted out addresses" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

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
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

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
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

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
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_non_dom)

      lodge_assessment(
        assessment_body: valid_cepc_rr_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

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

      expect(response_json[:data][:assessments][0]).to eq(
        {
          dateOfAssessment: "2020-05-04",
          dateRegistered: "2020-05-05",
          dwellingType: nil,
          typeOfAssessment: "CEPC",
          totalFloorArea: 99.0,
          assessmentId: "0000-0000-0000-0000-0000",
          assessor: nil,
          currentEnergyEfficiencyRating: 99,
          potentialEnergyEfficiencyRating: 99,
          currentCarbonEmission: 0.0,
          potentialCarbonEmission: 0.0,
          optOut: false,
          postcode: "A0 0AA",
          dateOfExpiry: "2026-05-04",
          addressId: nil,
          addressLine1: "2 Lonely Street",
          addressLine2: "",
          addressLine3: "",
          addressLine4: "",
          town: "Post-Town1",
          heatDemand: {
            currentSpaceHeatingDemand: 0.0,
            currentWaterHeatingDemand: 0.0,
            impactOfLoftInsulation: nil,
            impactOfCavityInsulation: nil,
            impactOfSolidWallInsulation: nil,
          },
          currentEnergyEfficiencyBand: "a",
          potentialEnergyEfficiencyBand: "a",
          recommendedImprovements: [],
          propertySummary: [],
          relatedPartyDisclosureNumber: nil,
          relatedPartyDisclosureText: nil,
          relatedAssessments: nil,
          status: "ENTERED",
        },
      )
    end

    it "can filter for domestic results" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_non_dom)

      lodge_assessment(
        assessment_body: valid_cepc_rr_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      response = assessments_search_by_postcode("A0 0AA")
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"][0]).to eq(nil)
    end
  end

  context "searching by ID" do
    it "returns the matching assessment" do
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
            dateOfAssessment: "2020-05-04",
            dateRegistered: "2020-05-04",
            tenure: "1",
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
            dateOfExpiry: "2030-05-04",
            town: "Post-Town1",
            addressId: "UPRN-000000000000",
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            lightingCostCurrent: "123.45",
            heatingCostCurrent: "365.98",
            hotWaterCostCurrent: "200.40",
            lightingCostPotential: "84.23",
            heatingCostPotential: "250.34",
            hotWaterCostPotential: "180.43",
            estimatedEnergyCost: "689.83",
            potentialEnergySaving: "174.83",
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
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
            status: "ENTERED",
            relatedAssessments: nil,
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end
  end

  context "searching by town and street name" do
    it "rejects a missing town" do
      response_body =
        assessments_search_by_street_name_and_town("Palmtree Road", "", [400])
          .body
      expect(JSON.parse(response_body, symbolize_names: true)).to eq(
        {
          errors: [
            {
              code: "MALFORMED_REQUEST", title: "Required query params missing"
            },
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
            {
              code: "MALFORMED_REQUEST", title: "Required query params missing"
            },
          ],
        },
      )
    end

    it "returns matching assessments" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      response =
        assessments_search_by_street_name_and_town(
          "1 Some Street",
          "Post-Town1",
        )

      response_json = JSON.parse(response.body)

      expected_response =
        JSON.parse(
          {
            assessor: nil,
            assessmentId: "0000-0000-0000-0000-0000",
            dateOfAssessment: "2020-05-04",
            dateRegistered: "2020-05-04",
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
            dateOfExpiry: "2030-05-04",
            town: "Post-Town1",
            addressId: nil,
            addressLine1: "1 Some Street",
            addressLine2: "",
            addressLine3: "",
            addressLine4: "",
            lightingCostCurrent: "123.45",
            heatingCostCurrent: "365.98",
            hotWaterCostCurrent: "200.40",
            lightingCostPotential: "84.23",
            heatingCostPotential: "250.34",
            hotWaterCostPotential: "180.43",
            estimatedEnergyCost: "689.83",
            potentialEnergySaving: "174.83",
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
            relatedPartyDisclosureNumber: nil,
            relatedPartyDisclosureText: "Related-Party-Disclosure-Text0",
            status: "ENTERED",
            tenure: "1",
            relatedAssessments: nil,
          }.to_json,
        )

      expect(response_json["data"]["assessments"][0]).to eq(expected_response)
    end

    it "does not return opted out assessments" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body_dom)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      opt_out_assessment("0000-0000-0000-0000-0000")

      response =
        assessments_search_by_street_name_and_town(
          "1 Some Street",
          "Post-Town1",
        )
      response_json = JSON.parse(response.body)

      expect(response_json["data"]["assessments"].length).to eq(0)
    end
  end
end
