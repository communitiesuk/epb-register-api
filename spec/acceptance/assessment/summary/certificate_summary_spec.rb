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

  context "when requesting assessments" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:assessor) do
      AssessorStub.new.fetch_request_body(
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
      )
    end

    before do
      add_countries
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)
    end

    context "when a certificate has been cancelled" do
      it "raises the AssessmentGone Error" do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
        ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
        expect(fetch_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [410]).status).to eq(410)
      end
    end

    context "when requesting a RdSAP assessment" do
      let(:related_assessment) { [] }
      let(:green_deal_plan) { [] }
      let(:superseded_by) { nil }
      let(:date_of_expiry) { "2030-05-03" }
      let(:date_of_registration) { "2020-05-04" }
      let(:assessment_id) { "0000-0000-0000-0000-0000" }

      let(:expected_response) do
        {
          "data": {
            "typeOfAssessment": "RdSAP",
            "assessmentId": assessment_id,
            "dateOfExpiry": date_of_expiry,
            "dateOfAssessment": "2020-05-04",
            "dateOfRegistration": date_of_registration,
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
            "supersededBy": superseded_by,
            "countryName": "Unknown",
            "relatedAssessments": related_assessment,
            "greenDealPlan": green_deal_plan,
          },
          "meta": {},
        }
      end

      before do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      end

      it "returns the expected response" do
        response =
          JSON.parse(
            fetch_certificate_summary(id: "0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        expect(response).to eq(expected_response)
      end

      context "when there is a related assessment" do
        let(:related_assessment_ids) do
          %w[
            0000-0000-0000-0000-0001
            0000-0000-0000-0000-0003
            0000-0000-0000-0000-0042
          ]
        end
        let(:related_assessment) do
          [{
            assessmentId: "0000-0000-0000-0000-0042",
            assessmentStatus: "ENTERED",
            assessmentType: "RdSAP",
            assessmentExpiryDate: "2030-05-03",
            optOut: false,
          },
           {
             assessmentId: "0000-0000-0000-0000-0003",
             assessmentStatus: "ENTERED",
             assessmentType: "RdSAP",
             assessmentExpiryDate: "2030-05-03",
             optOut: false,
           },
           {
             assessmentId: "0000-0000-0000-0000-0001",
             assessmentStatus: "ENTERED",
             assessmentType: "RdSAP",
             assessmentExpiryDate: "2030-05-03",
             optOut: false,
           }]
        end
        let(:superseded_by) { "0000-0000-0000-0000-0042" }

        before do
          schema = "RdSAP-Schema-20.0.0"
          xml = Nokogiri.XML Samples.xml(schema)
          xml.at("UPRN").children.to_s
          related_assessment_ids.each do |assessment_id|
            xml.at("RRN").children = assessment_id
            call_lodge_assessment scheme_id:, schema_name: schema, xml_document: xml, migrated: true
          end
        end

        it "returns the expected response" do
          response =
            JSON.parse(
              fetch_certificate_summary(id: "0000-0000-0000-0000-0000").body,
              symbolize_names: true,
            )

          expect(response).to eq(expected_response)
        end
      end

      context "when a green deal is attached" do
        let(:assessment_id) { "0000-0000-0000-0000-1111" }
        let(:green_deal_plan) do
          [{ greenDealPlanId: "ABC654321DEF",
             startDate: "2020-01-30",
             endDate: "2030-02-28",
             providerDetails: { name: "The Bank",
                                telephone: "0800 0000000",
                                email: "lender@example.com" },

             interest: { rate: "12.3",
                         fixed: true },
             chargeUplift: { amount: "1.25",
                             date: "2025-03-29" },
             ccaRegulated: true,
             structureChanged: false,
             measuresRemoved: false,
             measures: [{ product: "WarmHome lagging stuff (TM)",
                          sequence: 0,
                          repaidDate: "2025-03-29",
                          measureType: "Loft insulation" }],
             charges: [{ endDate: "2030-03-29",
                         sequence: 0,
                         startDate: "2020-03-29",
                         dailyCharge: 0.34 }],
             savings: [{ fuelCode: "39",
                         fuelSaving: 23_253,
                         standingChargeFraction: 0 },
                       { fuelCode: "40",
                         fuelSaving: -6331,
                         standingChargeFraction: -0.9 },
                       { fuelCode: "41",
                         fuelSaving: -15_561,
                         standingChargeFraction: 0 }],
             estimatedSavings: 1566 }]
        end
        let(:related_assessment) do
          [{
            assessmentId: "0000-0000-0000-0000-0000",
            assessmentStatus: "ENTERED",
            assessmentType: "RdSAP",
            assessmentExpiryDate: "2030-05-03",
            optOut: false,
          }]
        end
        let(:date_of_expiry) { "2034-10-09" }
        let(:date_of_registration) { "2024-10-10" }

        before do
          load_green_deal_data
          add_assessment_with_green_deal(
            type: "RdSAP",
            assessment_id: "0000-0000-0000-0000-1111",
            registration_date: "2024-10-10",
            green_deal_plan_id: "ABC654321DEF",
          )
        end

        it "returns the green deal data" do
          response =
            JSON.parse(
              fetch_certificate_summary(id: "0000-0000-0000-0000-1111").body,
              symbolize_names: true,
            )

          # the interest rate and charge uplift amount are big decimal values which
          # gets decoded to a string with the .to_json method
          expect(response).to eq(expected_response)
        end
      end
    end

    context "when requesting a SAP assessment" do
      let(:related_assessment) { [] }
      let(:superseded_by) { nil }
      let(:date_of_expiry) { "2030-05-03" }
      let(:date_of_registration) { "2020-05-04" }
      let(:assessment_id) { "0000-0000-0000-0000-0000" }
      let(:expected_response) do
        { data:
            { addendum: { stoneWalls: true },
              address: { addressLine1: "1 Some Street",
                         addressLine2: "Some Area",
                         addressLine3: "Some County",
                         addressLine4: nil,
                         postcode: "SW1A 2AA",
                         town: "Whitbury" },
              addressId: "UPRN-000000000000",
              assessmentId: "0000-0000-0000-0000-0001",
              assessor: { contactDetails: { email: "a@b.c", telephoneNumber: "111222333" },
                          firstName: "Someone",
                          lastName: "Person",
                          registeredBy: { name: "test scheme", schemeId: scheme_id },
                          schemeAssessorId: "SPEC000000" },
              countryName: "Unknown",
              currentCarbonEmission: "2.4",
              currentEnergyEfficiencyBand: "e",
              currentEnergyEfficiencyRating: 50,
              dateOfAssessment: "2020-05-04",
              dateOfExpiry: "2030-05-03",
              dateOfRegistration: "2020-05-04",
              dwellingType: "Mid-terrace house",
              electricitySmartMeterPresent: nil,
              environmentalImpactCurrent: 52,
              environmentalImpactPotential: 74,
              estimatedEnergyCost: "689.83",
              gasSmartMeterPresent: nil,
              heatDemand: { currentSpaceHeatingDemand: 13_120, currentWaterHeatingDemand: 2285 },
              heatingCostCurrent: "365.98",
              heatingCostPotential: "250.34",
              hotWaterCostCurrent: "200.40",
              hotWaterCostPotential: "180.43",
              lightingCostCurrent: "123.45",
              lightingCostPotential: "84.23",
              lzcEnergySources: nil,
              optOut: false,
              potentialCarbonEmission: "1.4",
              potentialEnergyEfficiencyBand: "c",
              potentialEnergyEfficiencyRating: 72,
              potentialEnergySaving: "174.83",
              primaryEnergyUse: "230",
              propertySummary:
                [{ description: "Brick walls",
                   energyEfficiencyRating: 0,
                   environmentalEfficiencyRating: 0,
                   name: "walls" },
                 { description: "Brick walls", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "walls" },
                 { description: "Slate roof", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "roof" },
                 { description: "slate roof", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "roof" },
                 { description: "Tiled floor", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "floor" },
                 { description: "Tiled floor", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "floor" },
                 { description: "Glass window", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "windows" },
                 { description: "Gas boiler", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "main_heating" },
                 { description: "Gas boiler", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "main_heating" },
                 { description: "Thermostat", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "main_heating_controls" },
                 { description: "Thermostat", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "main_heating_controls" },
                 { description: "Electric heater", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "secondary_heating" },
                 { description: "Gas boiler", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "hot_water" },
                 { description: "Energy saving bulbs", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "lighting" },
                 { description: "Draft Exclusion", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "air_tightness" }],
              recommendedImprovements:
                [{ energyPerformanceBandImprovement: "e",
                   energyPerformanceRatingImprovement: 50,
                   environmentalImpactRatingImprovement: 50,
                   greenDealCategoryCode: "1",
                   improvementCategory: "6",
                   improvementCode: "5",
                   improvementDescription: nil,
                   improvementTitle: "",
                   improvementType: "Z3",
                   indicativeCost: "£100 - £350",
                   sequence: 1,
                   typicalSaving: "360" },
                 { energyPerformanceBandImprovement: "d", energyPerformanceRatingImprovement: 60, environmentalImpactRatingImprovement: 64, greenDealCategoryCode: "3", improvementCategory: "2", improvementCode: nil, improvementDescription: "Improvement desc", improvementTitle: "", improvementType: "Z2", indicativeCost: "2000", sequence: 2, typicalSaving: "99" }],
              relatedAssessments: [],
              relatedPartyDisclosureNumber: 1,
              relatedPartyDisclosureText: nil,
              status: "ENTERED",
              supersededBy: nil,
              totalFloorArea: "69.0",
              typeOfAssessment: "SAP" },
          "meta": {} }
      end

      before do
        sap_schema = "SAP-Schema-18.0.0"
        sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
        sap_xml.at("RRN").content = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: sap_schema,
          migrated: true,
        )
      end

      it "returns data without the green deal plan" do
        response =
          JSON.parse(
            fetch_certificate_summary(id: "0000-0000-0000-0000-0001").body,
            symbolize_names: true,
          )
        expect(response).to eq(expected_response)
      end
    end

    context "when requesting a CEPC assessment" do
      before do
        cepc_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
        lodge_assessment(
          assessment_body: cepc_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
          migrated: true,
        )
      end

      it "raises a 400 error" do
        expect(fetch_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [400]).status).to eq(400)
      end
    end
  end
end
