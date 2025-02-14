# frozen_string_literal: true

require "date"

describe "Acceptance::CertificateSummary", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  it "returns 404 for an assessment that doesnt exist" do
    expect(fetch_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [404]).status).to eq(404)
  end

  it "returns 400 for an assessment id that is not valid" do
    expect(fetch_certificate_summary(id: "0000-0000-0000-0000-0000%23", accepted_responses: [400]).status).to eq(400)
  end

  describe "security scenarios" do
    it "rejects a request that is not authenticated" do
      expect(fetch_certificate_summary(id: "123", accepted_responses: [401], should_authenticate: false).status).to eq(401)
    end

    it "rejects a request with the wrong scopes" do
      expect(fetch_certificate_summary(id: "124", accepted_responses: [403], scopes: %w[wrong:scope]).status).to eq(403)
    end
  end

  context "when Improvement-Heading and Improvement-Summary elements exist" do
    it "returns the Improvement-Heading value as the improvementTitle and falls back to Improvement-Summary" do
      scheme_id = add_scheme_and_get_id
      assessor =
        AssessorStub.new.fetch_request_body(
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
        )
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")

      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)

      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )

      expected_response = {
        "data": {
          "typeOfAssessment": "RdSAP",
          "assessmentId": "0000-0000-0000-0000-0000",
          "dateOfExpiry": "2030-05-03",
          "dateOfAssessment": "2020-05-04",
          "dateOfRegistration": "2020-05-04",
          "address": {
            "addressLine1": "1 Some Street",
            "addressLine2": "",
            "addressLine3": "",
            "addressLine4": nil,
            "town": "Whitbury",
            "postcode": "SW1A 2AA",
          },
          "assessor": {
            "firstName": "Someone",
            "lastName": "Person",
            "registeredBy": {
              "name": "test scheme",
              "schemeId": scheme_id,
            },
            "schemeAssessorId": "SPEC000000",
            "contactDetails": {
              "email": "a@b.c",
              "telephoneNumber": "0555 497 2848",
            },
          },
          "currentCarbonEmission": "2.4",
          "currentEnergyEfficiencyBand": "e",
          "currentEnergyEfficiencyRating": 50,
          "dwellingType": "Mid-terrace house",
          "estimatedEnergyCost": "689.83",
          "heatDemand": {
            "currentSpaceHeatingDemand": 13_120,
            "currentWaterHeatingDemand": 2285,
          },
          "heatingCostCurrent": "365.98",
          "heatingCostPotential": "250.34",
          "hotWaterCostCurrent": "200.40",
          "hotWaterCostPotential": "180.43",
          "lightingCostCurrent": "123.45",
          "lightingCostPotential": "84.23",
          "potentialCarbonEmission": "1.4",
          "potentialEnergyEfficiencyBand": "c",
          "potentialEnergyEfficiencyRating": 72,
          "potentialEnergySaving": "174.83",
          "propertySummary": [
            {
              "energyEfficiencyRating": 1,
              "environmentalEfficiencyRating": 1,
              "name": "wall",
              "description": "Solid brick, as built, no insulation (assumed)",
            },
            {
              "energyEfficiencyRating": 4,
              "environmentalEfficiencyRating": 4,
              "name": "wall",
              "description": "Cavity wall, as built, insulated (assumed)",
            },
            {
              "energyEfficiencyRating": 2,
              "environmentalEfficiencyRating": 2,
              "name": "roof",
              "description": "Pitched, 25 mm loft insulation",
            },
            {
              "energyEfficiencyRating": 4,
              "environmentalEfficiencyRating": 4,
              "name": "roof",
              "description": "Pitched, 250 mm loft insulation",
            },
            {
              "energyEfficiencyRating": 0,
              "environmentalEfficiencyRating": 0,
              "name": "floor",
              "description": "Suspended, no insulation (assumed)",
            },
            {
              "energyEfficiencyRating": 0,
              "environmentalEfficiencyRating": 0,
              "name": "floor",
              "description": "Solid, insulated (assumed)",
            },
            {
              "energyEfficiencyRating": 3,
              "environmentalEfficiencyRating": 3,
              "name": "window",
              "description": "Fully double glazed",
            },
            {
              "energyEfficiencyRating": 3,
              "environmentalEfficiencyRating": 1,
              "name": "main_heating",
              "description": "Boiler and radiators, anthracite",
            },
            {
              "energyEfficiencyRating": 4,
              "environmentalEfficiencyRating": 4,
              "name": "main_heating",
              "description": "Boiler and radiators, mains gas",
            },
            {
              "energyEfficiencyRating": 4,
              "environmentalEfficiencyRating": 4,
              "name": "main_heating_controls",
              "description": "Programmer, room thermostat and TRVs",
            },
            {
              "energyEfficiencyRating": 5,
              "environmentalEfficiencyRating": 5,
              "name": "main_heating_controls",
              "description": "Time and temperature zone control",
            },
            {
              "energyEfficiencyRating": 4,
              "environmentalEfficiencyRating": 4,
              "name": "hot_water",
              "description": "From main system",
            },
            {
              "energyEfficiencyRating": 4,
              "environmentalEfficiencyRating": 4,
              "name": "lighting",
              "description": "Low energy lighting in 50% of fixed outlets",
            },
            {
              "energyEfficiencyRating": 0,
              "environmentalEfficiencyRating": 0,
              "name": "secondary_heating",
              "description": "Room heaters, electric",
            },
          ],
          "recommendedImprovements": [
            {
              "energyPerformanceRatingImprovement": 50,
              "environmentalImpactRatingImprovement": 50,
              "greenDealCategoryCode": "1",
              "improvementCategory": "6",
              "improvementCode": "5",
              "improvementDescription": nil,
              "improvementTitle": "",
              "improvementType": "Z3",
              "indicativeCost": "£100 - £350",
              "sequence": 1,
              "typicalSaving": "360",
              "energyPerformanceBandImprovement": "e",
            },
            {
              "energyPerformanceRatingImprovement": 60,
              "environmentalImpactRatingImprovement": 64,
              "greenDealCategoryCode": "3",
              "improvementCategory": "2",
              "improvementCode": "1",
              "improvementDescription": nil,
              "improvementTitle": "",
              "improvementType": "Z2",
              "indicativeCost": "2000",
              "sequence": 2,
              "typicalSaving": "99",
              "energyPerformanceBandImprovement": "d",
            },
            {
              "energyPerformanceRatingImprovement": 60,
              "environmentalImpactRatingImprovement": 64,
              "greenDealCategoryCode": "3",
              "improvementCategory": "2",
              "improvementCode": nil,
              "improvementDescription": "Improvement desc",
              "improvementTitle": "",
              "improvementType": "Z2",
              "indicativeCost": "1000",
              "sequence": 3,
              "typicalSaving": "99",
              "energyPerformanceBandImprovement": "d",
            },
          ],
          "lzcEnergySources": nil,
          "relatedPartyDisclosureNumber": nil,
          "relatedPartyDisclosureText": "No related party",
          "totalFloorArea": "55.0",
          "status": "ENTERED",
          "environmentalImpactCurrent": 52,
          "environmentalImpactPotential": 74,
          "primaryEnergyUse": "230",
          "addendum": {
            "addendumNumber": [
              1,
              8,
            ],
            "stoneWalls": true,
            "systemBuild": true,
          },
          "gasSmartMeterPresent": nil,
          "electricitySmartMeterPresent": nil,
          "addressId": "UPRN-000000000000",
          "optOut": false,
          "supersededBy": nil,
          "relatedAssessments": [],
          "greenDealPlan": [],
        },
        "meta": {},
      }

      response =
        JSON.parse(
          fetch_certificate_summary(id: "0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

      expect(response).to eq(expected_response)
    end
  end
end
