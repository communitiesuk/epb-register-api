# frozen_string_literal: true

require "date"

describe "Acceptance::ScotlandCertificateSummary", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  it "returns 404 for an assessment that doesnt exist" do
    expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [404]).status).to eq(404)
  end

  it "returns 400 for an assessment id that is not valid" do
    expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000%23", accepted_responses: [400]).status).to eq(400)
  end

  it_behaves_like "when checking an endpoint requires bearer token access", end_point: "scotland/assessments/some_id/certificate-summary", scopes: %w[scotland_assessment:fetch]

  context "when requesting Scottish assessments" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:assessor) do
      AssessorStub.new.fetch_request_body
    end

    before do
      add_countries
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: assessor)
    end

    context "when a certificate has been cancelled" do
      it "raises the AssessmentGone Error" do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-19.0")
        lodge_scottish_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: true,
        )
        ActiveRecord::Base.connection.exec_query("UPDATE scotland.assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
        expect(fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000", accepted_responses: [410]).status).to eq(410)
      end
    end

    context "when requesting a Scottish RdSAP assessment" do
      let(:related_assessment) { [] }
      let(:green_deal_plan) { [] }
      let(:superseded_by) { nil }
      let(:date_of_expiry) { "2030-05-03" }
      let(:date_of_registration) { "2020-05-04" }
      let(:assessment_id) { "0000-0000-0000-0000-0000" }

      let(:expected_response) do
        {
          addendum: nil,
          address: { addressLine1: "1 Some Street", addressLine2: "", addressLine3: "", addressLine4: "", postcode: "FK1 1XE", town: "Newkirk" },
          addressId: "RRN-0000-0000-0000-0000-0000",
          assessmentId: "0000-0000-0000-0000-0000",
          assessor:
              {
                contactDetails: { email: "a@b.c", telephoneNumber: "0555 497 2848", address: "12 Epc Street, Newkirk, FK1 1XE" },
                companyName: "Test EPCs 4U",
                firstName: "Someone",
                lastName: "Person",
                registeredBy: { name: "test scheme", schemeId: scheme_id },
                schemeAssessorId: "SPEC000000",
              },
          countryName: "Scotland",
          currentCarbonEmission: 1.7,
          carbonEmissionsCurrentPerFloorArea: 25,
          currentEnergyEfficiencyBand: "c",
          currentEnergyEfficiencyRating: 79,
          dateOfAssessment: "2023-06-27",
          dateOfExpiry: "2033-06-26",
          dateOfRegistration: "2023-06-27",
          dwellingType: "Top-floor flat",
          electricitySmartMeterPresent: nil,
          environmentalImpactCurrent: 80,
          environmentalImpactPotential: 80,
          estimatedEnergyCost: "933.00",
          gasSmartMeterPresent: nil,
          greenDealPlan: [],
          heatDemand: { currentSpaceHeatingDemand: 3865, currentWaterHeatingDemand: 1955 },
          heatingCostCurrent: "585",
          heatingCostPotential: "585",
          hotWaterCostCurrent: "226",
          hotWaterCostPotential: "226",
          lightingCostCurrent: "122",
          lightingCostPotential: "122",
          lzcEnergySources: nil,
          optOut: false,
          potentialCarbonEmission: 1.7,
          potentialEnergyEfficiencyBand: "c",
          potentialEnergyEfficiencyRating: 79,
          potentialEnergySaving: "0.00",
          primaryEnergyUse: 145,
          propertySummary:
              [
                { description: "Timber frame, as built, insulated (assumed)", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "wall" },
                { description: "Solid brick, as built, insulated (assumed)", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "wall" },
                { description: "Pitched, insulated (assumed)", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "roof" },
                { description: "(another dwelling below)", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "floor" },
                { description: "Fully double glazed", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "window" },
                { description: "Boiler and radiators, mains gas", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "main_heating" },
                { description: "Programmer, room thermostat and TRVs", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "main_heating_controls" },
                { description: "From main system", energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "hot_water" },
                { description: "Low energy lighting in all fixed outlets", energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "lighting" },
                { description: "None", energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "secondary_heating" },
              ],
          recommendedImprovements: [],
          relatedAssessments: [],
          relatedPartyDisclosureNumber: 1,
          relatedPartyDisclosureText: nil,
          status: "ENTERED",
          supersededBy: nil,
          totalFloorArea: 66.0,
          schemaType: "RdSAP-Schema-S-19.0",
          typeOfAssessment: "RdSAP",
        }
      end

      before do
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-19.0")
        lodge_scottish_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: true,
        )
      end

      it "returns the expected response" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )
        expect(response[:data]).to eq(expected_response)
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
            assessmentExpiryDate: "2033-06-26",
            optOut: false,
          },
           {
             assessmentId: "0000-0000-0000-0000-0003",
             assessmentStatus: "ENTERED",
             assessmentType: "RdSAP",
             assessmentExpiryDate: "2033-06-26",
             optOut: false,
           }]
        end
        let(:superseded_by) { "0000-0000-0000-0000-0042" }

        before do
          schema = "RdSAP-Schema-S-19.0"
          xml = Nokogiri.XML Samples.xml(schema)
          xml.at("UPRN").children.to_s
          related_assessment_ids.each do |assessment_id|
            xml.at("RRN").children = assessment_id
            lodge_scottish_assessment(
              assessment_body: xml.to_xml,
              accepted_responses: [201],
              auth_data: {
                scheme_ids: [scheme_id],
              },
              schema_name: schema,
              migrated: true,
            )
          end
        end

        it "returns the expected response" do
          ActiveRecord::Base.connection.exec_query("UPDATE scotland.assessments_address_id SET address_id = 'RRN-0000-0000-0000-0000-0001' WHERE assessment_id IN ( '0000-0000-0000-0000-0001', '0000-0000-0000-0000-0003', '0000-0000-0000-0000-0042') ")

          response =
            JSON.parse(
              fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0001").body,
              symbolize_names: true,
            )
          expect(response[:data][:relatedAssessments]).to eq(related_assessment)
        end
      end

      # context "when a green deal is attached" do
      #   let(:assessment_id) { "0000-0000-0000-0000-1111" }
      #   let(:green_deal_plan) do
      #     [{ greenDealPlanId: "ABC654321DEF",
      #        startDate: "2020-01-30",
      #        endDate: "2030-02-28",
      #        providerDetails: { name: "The Bank",
      #                           telephone: "0800 0000000",
      #                           email: "lender@example.com" },
      #
      #        interest: { rate: "12.3",
      #                    fixed: true },
      #        chargeUplift: { amount: "1.25",
      #                        date: "2025-03-29" },
      #        ccaRegulated: true,
      #        structureChanged: false,
      #        measuresRemoved: false,
      #        measures: [{ product: "WarmHome lagging stuff (TM)",
      #                     sequence: 0,
      #                     repaidDate: "2025-03-29",
      #                     measureType: "Loft insulation" }],
      #        charges: [{ endDate: "2030-03-29",
      #                    sequence: 0,
      #                    startDate: "2020-03-29",
      #                    dailyCharge: 0.34 }],
      #        savings: [{ fuelCode: "39",
      #                    fuelSaving: 23_253,
      #                    standingChargeFraction: 0 },
      #                  { fuelCode: "40",
      #                    fuelSaving: -6331,
      #                    standingChargeFraction: -0.9 },
      #                  { fuelCode: "41",
      #                    fuelSaving: -15_561,
      #                    standingChargeFraction: 0 }],
      #        estimatedSavings: 1566 }]
      #   end
      #   let(:related_assessment) do
      #     [{
      #       assessmentId: "0000-0000-0000-0000-0000",
      #       assessmentStatus: "ENTERED",
      #       assessmentType: "RdSAP",
      #       assessmentExpiryDate: "2030-05-03",
      #       optOut: false,
      #     }]
      #   end
      #   let(:date_of_expiry) { "2034-10-09" }
      #   let(:date_of_registration) { "2024-10-10" }
      #
      #   before do
      #     load_green_deal_data
      #     add_assessment_with_green_deal(
      #       type: "RdSAP",
      #       assessment_id: "0000-0000-0000-0000-1111",
      #       registration_date: "2024-10-10",
      #       green_deal_plan_id: "ABC654321DEF",
      #     )
      #   end
      #
      #   it "returns the green deal data" do
      #     response =
      #       JSON.parse(
      #         fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-1111").body,
      #         symbolize_names: true,
      #       )
      #
      #     # the interest rate and charge uplift amount are big decimal values which
      #     # gets decoded to a string with the .to_json method
      #     expect(response).to eq(expected_response)
      #   end
      # end
    end

    context "when requesting an RdSAP-Schema-S-21.0 assessment" do
      let(:related_assessment) { [] }
      let(:green_deal_plan) { [] }
      let(:superseded_by) { nil }
      let(:date_of_expiry) { "2030-05-03" }
      let(:date_of_registration) { "2020-05-04" }
      let(:assessment_id) { "0000-0000-0000-0000-0000" }

      let(:expected_response) do
        { typeOfAssessment: "RdSAP",
          assessmentId: "0000-0000-0000-0000-0000",
          dateOfExpiry: "2033-06-26",
          dateOfAssessment: "2023-06-27",
          dateOfRegistration: "2023-06-27",
          address: { addressLine1: "1 Some Street", addressLine2: "", addressLine3: "", addressLine4: "", town: "Newkirk", postcode: "FK1 1XE" },
          assessor:
           { schemeAssessorId: "SPEC000000",
             companyName: "Test EPCs 4U",
             contactDetails: { email: "a@b.c", address: "12 Epc Street, Newkirk, FK1 1XE", telephoneNumber: "0555 497 2848" },
             firstName: "Someone",
             lastName: "Person",
             registeredBy: { name: "test scheme", schemeId: scheme_id } },
          currentCarbonEmission: 3.7,
          carbonEmissionsCurrentPerFloorArea: 22.0,
          currentEnergyEfficiencyBand: "c",
          currentEnergyEfficiencyRating: 80,
          dwellingType: "Detached house",
          estimatedEnergyCost: "1492.00",
          heatDemand: { currentSpaceHeatingDemand: 13_063, currentWaterHeatingDemand: 2612 },
          heatingCostCurrent: "1113",
          heatingCostPotential: "1113",
          hotWaterCostCurrent: "294",
          hotWaterCostPotential: "294",
          lightingCostCurrent: "85",
          lightingCostPotential: "85",
          potentialCarbonEmission: 3.6,
          potentialEnergyEfficiencyBand: "b",
          potentialEnergyEfficiencyRating: 83,
          potentialEnergySaving: "0.00",
          propertySummary:
           [{ energyEfficiencyRating: 4,
              environmentalEfficiencyRating: 4,
              name: "wall",
              description: "Timber frame, as built, insulated (assumed)" },
            { energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "roof", description: "Pitched, 300 mm loft insulation" },
            { energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "roof", description: "Pitched, insulated" },
            { energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "floor", description: "Solid, insulated (assumed)" },
            { energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "floor", description: "To unheated space, insulated (assumed)" },
            { energyEfficiencyRating: 3, environmentalEfficiencyRating: 3, name: "window", description: "Fully double glazed" },
            { energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "air_tightness", description: "(not tested)" },
            { energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "main_heating", description: "Boiler and radiators, mains gas" },
            { energyEfficiencyRating: 3,
              environmentalEfficiencyRating: 3,
              name: "main_heating_controls",
              description: "Room thermostat and TRVs" },
            { energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "hot_water", description: "From main system" },
            { energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "lighting", description: "Good lighting efficiency" },
            { energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "secondary_heating", description: "None" }],
          recommendedImprovements:
           [{ energyPerformanceRatingImprovement: 83,
              environmentalImpactRatingImprovement: 81,
              greenDealCategoryCode: nil,
              improvementCategory: "5",
              improvementCode: "34",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "U",
              indicativeCost: "£8,000 - £10,000",
              sequence: 1,
              typicalSaving: "236",
              energyPerformanceBandImprovement: "b" }],
          lzcEnergySources: nil,
          relatedPartyDisclosureNumber: 1,
          relatedPartyDisclosureText: nil,
          totalFloorArea: 173,
          status: "ENTERED",
          environmentalImpactCurrent: 80,
          environmentalImpactPotential: 81,
          primaryEnergyUse: 121.0,
          addendum: nil,
          gasSmartMeterPresent: false,
          electricitySmartMeterPresent: false,
          addressId: "RRN-0000-0000-0000-0000-0000",
          optOut: false,
          relatedAssessments: [],
          supersededBy: nil,
          countryName: "Scotland",
          schemaType: "RdSAP-Schema-S-21.0",
          greenDealPlan: [] }
      end

      before do
        domestic_rdsap_21_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-21.0")
        lodge_scottish_assessment(
          assessment_body: domestic_rdsap_21_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-21.0",
          migrated: true,
        )
      end

      it "returns the expected response" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )

        expect(response[:data]).to eq(expected_response)
      end
    end

    context "when requesting an RdSAP-Schema-S-18.0 assessment" do
      let(:expected_response) do
        { typeOfAssessment: "RdSAP",
          assessmentId: "0000-0000-0000-0000-0000",
          dateOfExpiry: "2029-01-29",
          dateOfAssessment: "2019-01-30",
          dateOfRegistration: "2019-01-30",
          address:
           { addressLine1: "1 Some Street",
             addressLine2: "",
             addressLine3: "",
             addressLine4: "",
             town: "Newkirk",
             postcode: "FK1 1XE" },
          assessor:
           { schemeAssessorId: "SPEC000000",
             companyName: "Test EPCs 4U",
             contactDetails: { email: "a@b.c", address: "12 Epc Street, Newkirk, FK1 1XE", telephoneNumber: "0555 497 2848" },
             firstName: "Someone",
             lastName: "Person",
             registeredBy: { name: "test scheme", schemeId: scheme_id } },
          currentCarbonEmission: 6.4,
          carbonEmissionsCurrentPerFloorArea: 73.0,
          currentEnergyEfficiencyBand: "e",
          currentEnergyEfficiencyRating: 51,
          dwellingType: "End-terrace house",
          estimatedEnergyCost: "1281.00",
          heatDemand: { currentSpaceHeatingDemand: 13_420, currentWaterHeatingDemand: 3531 },
          heatingCostCurrent: "974",
          heatingCostPotential: "644",
          hotWaterCostCurrent: "244",
          hotWaterCostPotential: "72",
          lightingCostCurrent: "63",
          lightingCostPotential: "63",
          potentialCarbonEmission: 2.7,
          potentialEnergyEfficiencyBand: "c",
          potentialEnergyEfficiencyRating: 80,
          potentialEnergySaving: "502.00",
          propertySummary:
           [{ energyEfficiencyRating: 3, environmentalEfficiencyRating: 3, name: "wall", description: "Cavity wall, filled cavity" },
            { energyEfficiencyRating: 4,
              environmentalEfficiencyRating: 4,
              name: "roof",
              description: "Pitched, 150 mm loft insulation" },
            { energyEfficiencyRating: 1,
              environmentalEfficiencyRating: 1,
              name: "roof",
              description: "Pitched, no insulation (assumed)" },
            { energyEfficiencyRating: 0,
              environmentalEfficiencyRating: 0,
              name: "floor",
              description: "Solid, no insulation (assumed)" },
            { energyEfficiencyRating: 3, environmentalEfficiencyRating: 3, name: "window", description: "Fully double glazed" },
            { energyEfficiencyRating: 4,
              environmentalEfficiencyRating: 4,
              name: "main_heating",
              description: "Boiler and radiators, mains gas" },
            { energyEfficiencyRating: 3,
              environmentalEfficiencyRating: 3,
              name: "main_heating_controls",
              description: "Programmer, TRVs and bypass" },
            { energyEfficiencyRating: 2,
              environmentalEfficiencyRating: 2,
              name: "hot_water",
              description: "From main system, no cylinder thermostat" },
            { energyEfficiencyRating: 5,
              environmentalEfficiencyRating: 5,
              name: "lighting",
              description: "Low energy lighting in all fixed outlets" },
            { energyEfficiencyRating: 0,
              environmentalEfficiencyRating: 0,
              name: "secondary_heating",
              description: "Room heaters, mains gas" }],
          recommendedImprovements:
           [{ energyPerformanceRatingImprovement: 54,
              environmentalImpactRatingImprovement: 46,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "58",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "W2",
              indicativeCost: "£4,000 - £6,000",
              sequence: 1,
              typicalSaving: "89",
              energyPerformanceBandImprovement: "e" },
            { energyPerformanceRatingImprovement: 55,
              environmentalImpactRatingImprovement: 47,
              greenDealCategoryCode: "3",
              improvementCategory: "5",
              improvementCode: "3",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "C",
              indicativeCost: "£15 - £30",
              sequence: 2,
              typicalSaving: "14",
              energyPerformanceBandImprovement: "d" },
            { energyPerformanceRatingImprovement: 55,
              environmentalImpactRatingImprovement: 47,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "10",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "D",
              indicativeCost: "£80 - £120",
              sequence: 3,
              typicalSaving: "12",
              energyPerformanceBandImprovement: "d" },
            { energyPerformanceRatingImprovement: 56,
              environmentalImpactRatingImprovement: 48,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "4",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "F",
              indicativeCost: "£200 - £400",
              sequence: 4,
              typicalSaving: "23",
              energyPerformanceBandImprovement: "d" },
            { energyPerformanceRatingImprovement: 59,
              environmentalImpactRatingImprovement: 51,
              greenDealCategoryCode: "3",
              improvementCategory: "5",
              improvementCode: "14",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "G",
              indicativeCost: "£350 - £450",
              sequence: 5,
              typicalSaving: "75",
              energyPerformanceBandImprovement: "d" },
            { energyPerformanceRatingImprovement: 67,
              environmentalImpactRatingImprovement: 62,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "20",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "I",
              indicativeCost: "£2,200 - £3,000",
              sequence: 6,
              typicalSaving: "217",
              energyPerformanceBandImprovement: "d" },
            { energyPerformanceRatingImprovement: 68,
              environmentalImpactRatingImprovement: 65,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "19",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "N",
              indicativeCost: "£4,000 - £6,000",
              sequence: 7,
              typicalSaving: "38",
              energyPerformanceBandImprovement: "d" },
            { energyPerformanceRatingImprovement: 70,
              environmentalImpactRatingImprovement: 66,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "56",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "O3",
              indicativeCost: "£1,000 - £1,400",
              sequence: 8,
              typicalSaving: "34",
              energyPerformanceBandImprovement: "c" },
            { energyPerformanceRatingImprovement: 80,
              environmentalImpactRatingImprovement: 75,
              greenDealCategoryCode: "2",
              improvementCategory: "5",
              improvementCode: "34",
              improvementDescription: nil,
              improvementTitle: "",
              improvementType: "U",
              indicativeCost: "£5,000 - £8,000",
              sequence: 9,
              typicalSaving: "279",
              energyPerformanceBandImprovement: "c" }],
          lzcEnergySources: nil,
          relatedPartyDisclosureNumber: 1,
          relatedPartyDisclosureText: nil,
          totalFloorArea: 87,
          status: "ENTERED",
          environmentalImpactCurrent: 43,
          environmentalImpactPotential: 75,
          primaryEnergyUse: 414.0,
          addendum: nil,
          gasSmartMeterPresent: nil,
          electricitySmartMeterPresent: nil,
          addressId: "RRN-0000-0000-0000-0000-0000",
          optOut: false,
          relatedAssessments: [],
          supersededBy: nil,
          countryName: "Scotland",
          schemaType: "RdSAP-Schema-S-18.0",
          greenDealPlan: [] }
      end

      before do
        domestic_rdsap_18_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-S-18.0")
        lodge_scottish_assessment(
          assessment_body: domestic_rdsap_18_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-18.0",
          migrated: true,
        )
      end

      it "returns the expected response" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0000").body,
            symbolize_names: true,
          )

        expect(response[:data]).to eq(expected_response)
      end
    end

    context "when requesting a Scottish SAP assessment" do
      let(:expected_response) do
        { data:
           { typeOfAssessment: "SAP",
             assessmentId: "0000-0000-0000-0000-0067",
             dateOfExpiry: "2033-06-26",
             dateOfAssessment: "2023-06-27",
             dateOfRegistration: "2023-06-27",
             address: { addressLine1: "1 LOVELY ROAD", addressLine2: "NICE ESTATE", addressLine3: "", addressLine4: "", town: "TOWN", postcode: "EH1 2NG" },
             assessor:
              { schemeAssessorId: "SPEC000000",
                companyName: "Test Homes Limited",
                contactDetails: { email: "a@b.c", telephoneNumber: "111222333", address: "Assessor House Energy Business Park, Town Road, Scotlandshire, Newkirk, FK1 1XE" },
                firstName: "Someone",
                lastName: "Person",
                registeredBy: { name: "test scheme", schemeId: scheme_id } },
             currentCarbonEmission: 2.2,
             carbonEmissionsCurrentPerFloorArea: 12.1,
             currentEnergyEfficiencyBand: "b",
             currentEnergyEfficiencyRating: 91,
             dwellingType: "Detached house",
             estimatedEnergyCost: "837.00",
             heatDemand: { currentSpaceHeatingDemand: nil, currentWaterHeatingDemand: nil },
             heatingCostCurrent: "603",
             heatingCostPotential: "603",
             hotWaterCostCurrent: "152",
             hotWaterCostPotential: "152",
             lightingCostCurrent: "82",
             lightingCostPotential: "82",
             potentialCarbonEmission: 2.2,
             potentialEnergyEfficiencyBand: "b",
             potentialEnergyEfficiencyRating: 91,
             potentialEnergySaving: "0.00",
             propertySummary:
              [{ energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "walls", description: "Average thermal transmittance 0.21 W/m²K" },
               { energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "roof", description: "Average thermal transmittance 0.14 W/m²K" },
               { energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "floor", description: "Average thermal transmittance 0.16 W/m²K" },
               { energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "windows", description: "High performance glazing" },
               { energyEfficiencyRating: 5, environmentalEfficiencyRating: 4, name: "main_heating", description: "Boiler and radiators, mains gas" },
               { energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "main_heating_controls", description: "Time and temperature zone control" },
               { energyEfficiencyRating: 0, environmentalEfficiencyRating: 0, name: "secondary_heating", description: "None" },
               { energyEfficiencyRating: 4, environmentalEfficiencyRating: 4, name: "hot_water", description: "From main system" },
               { energyEfficiencyRating: 5, environmentalEfficiencyRating: 5, name: "lighting", description: "Excelent lighting efficiency" },
               { energyEfficiencyRating: 4,
                 environmentalEfficiencyRating: 4,
                 name: "air_tightness",
                 description: "Air permeability [AP50] = 4.0 m³/h.m² (as tested)" }],
             recommendedImprovements: [],
             lzcEnergySources: [11],
             relatedPartyDisclosureNumber: 1,
             relatedPartyDisclosureText: nil,
             totalFloorArea: 184.0,
             status: "ENTERED",
             environmentalImpactCurrent: 88,
             environmentalImpactPotential: 88,
             primaryEnergyUse: 63,
             addendum: nil,
             gasSmartMeterPresent: true,
             electricitySmartMeterPresent: true,
             addressId: "RRN-0000-0000-0000-0000-0067",
             optOut: false,
             relatedAssessments: [],
             supersededBy: nil,
             schemaType: "SAP-Schema-S-19.0.0",
             countryName: "Scotland" },
          meta: {} }
      end

      before do
        sap_schema = "SAP-Schema-S-19.0.0"
        sap_xml = Nokogiri.XML(Samples.xml(sap_schema))
        sap_xml.at("RRN").content = "0000-0000-0000-0000-0067"
        lodge_scottish_assessment(
          assessment_body: sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: sap_schema,
          migrated: true,
        )
      end

      it "returns Scottish SAP" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0067").body,
            symbolize_names: true,
          )
        expect(response[:data]).to eq(expected_response[:data])
      end
    end

    context "when requesting a Scottish CEPC assessment" do
      before do
        cepc_xml = Nokogiri.XML Samples.xml("CEPC-S-7.1", "cepc")
        cepc_xml
          .xpath("//*[local-name() = 'RRN']")
          .each do |node|
          node.content = "0000-0000-0000-0002-0000"
        end
        lodge_scottish_assessment(
          assessment_body: cepc_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-S-7.1",
          migrated: true,
        )
      end

      it "returns the expected CEPC" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0002-0000").body,
            symbolize_names: true,
          )

        expected_response = { typeOfAssessment: "CEPC",
                              assessmentId: "0000-0000-0000-0002-0000",
                              dateOfExpiry: "2033-06-26",
                              reportType: "3",
                              dateOfAssessment: "2023-06-27",
                              dateOfRegistration: "2023-06-27",
                              address:
                               { addressLine1: "Non-dom Property", addressLine2: "Some Street", addressLine3: "Bigger Line", addressLine4: "", town: "Town", postcode: "FK1 1XE" },
                              assessor:
                               { schemeAssessorId: "SPEC000000",
                                 contactDetails: { email: "sessor@email.co.uk", tradingAddress: "6 Unit Business Park Town", telephoneNumber: "00000000073" },
                                 companyName: "EPC R Us Ltd",
                                 insurer: "Insurance Company",
                                 policyNo: "POL000000",
                                 insurerEffectiveDate: "2022-10-22",
                                 insurerExpiryDate: "2023-10-21",
                                 insurerPiLimit: "5000000",
                                 firstName: "Someone",
                                 lastName: "Person",
                                 registeredBy: { name: "test scheme", schemeId: scheme_id } },
                              technicalInformation: { mainHeatingFuel: "LPG", buildingEnvironment: "Heating and Natural Ventilation", floorArea: 109 },
                              currentEnergyEfficiencyRating: 120,
                              currentEnergyEfficiencyBand: "G",
                              potentialEnergyEfficiencyRating: 17,
                              potentialEnergyEfficiencyBand: "B+",
                              newBuildBenchmarkRating: 56,
                              newBuildBenchmarkBand: "D",
                              comparativeAssetRating: 65,
                              epcRatingBer: 120.47,
                              approximateEnergyUse: 523,
                              propertyType: { propertyTypeLongDescription: "Hotels", propertyTypeShortDescription: "Hotel" },
                              compliant2002: "N",
                              renewableEnergySources: %w[None],
                              electricitySources: ["Grid supplied"],
                              primaryEnergyIndicator: 616,
                              calculationTool: "DesignBuilder Software Ltd, DesignBuilder SBEM, v7.2.0, SBEM, v6.1.e.0",
                              ter2002: 118.01,
                              ter: 55.93,
                              shortPaybackRecommendations: [{ code: "EPC-H7", text: "Add optimum start/stop to the heating system.", cO2Impact: "MEDIUM" },
                                                            { code: "EPC-H8", text: "Add weather compensation controls to heating system.", cO2Impact: "MEDIUM" },
                                                            { code: "EPC-H5", text: "Add local time control to heating system.", cO2Impact: "MEDIUM" },
                                                            { code: "EPC-V1",
                                                              text:
                                                                "In some spaces, the solar gain limit defined in the NCM is exceeded, which might cause overheating. Consider solar control measures such as the application of reflective coating or shading devices to windows.",
                                                              cO2Impact: "MEDIUM" },
                                                            { code: "EPC-E3",
                                                              text: "Some solid walls are poorly insulated - introduce or improve internal wall insulation.",
                                                              cO2Impact: "MEDIUM" },
                                                            { code: "EPC-F4", text: "Consider switching from oil or LPG to biomass.", cO2Impact: "HIGH" },
                                                            { code: "EPC-E7",
                                                              text: "Carry out a pressure test, identify and treat identified air leakage. Enter result in EPC calculation.",
                                                              cO2Impact: "MEDIUM" },
                                                            { code: "EPC-E8",
                                                              text: "Some glazing is poorly insulated. Replace/improve glazing and/or frames. ",
                                                              cO2Impact: "MEDIUM" }],
                              mediumPaybackRecommendations: [{ code: "EPC-E2",
                                                               text: "Roof is poorly insulated. Install or improve insulation of roof.",
                                                               cO2Impact: "MEDIUM" }],
                              longPaybackRecommendations: [],
                              otherPaybackRecommendations: [],
                              addressId: "RRN-0000-0000-0000-0002-0000",
                              optOut: false,
                              relatedAssessments: [],
                              supersededBy: nil,
                              schemaType: "CEPC-S-7.1",
                              countryName: "Scotland" }

        expect(response[:data]).to eq(expected_response)
      end
    end

    context "when requesting a Scottish Action Plan assessment" do
      before do
        action_plan_xml = Nokogiri.XML Samples.xml("CS63-S-7.0", "cs63")
        action_plan_xml
          .xpath("//*[local-name() = 'RRN']")
          .each do |node|
          node.content = "0000-0000-0000-0003-0000"
        end
        lodge_scottish_assessment(
          assessment_body: action_plan_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CS63-S-7.0",
          migrated: true,
        )
      end

      it "returns the expected Action Plan" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0003-0000").body,
            symbolize_names: true,
          )

        expected_response = { typeOfAssessment: "CS63",
                              assessmentId: "0000-0000-0000-0003-0000",
                              epcAssessmentId: "0000-0000-0000-0000-0001",
                              saleLeaseDate: "2023-06-27",
                              reportType: "9",
                              dateOfAssessment: "2023-06-27",
                              planReportDate: "2023-06-27",
                              address: { addressLine1: "Non-dom Property", addressLine2: "", addressLine3: "", addressLine4: "", town: "Town", postcode: "FK1 1XE" },
                              assessor:
                               { schemeAssessorId: "SPEC000000",
                                 contactDetails: { email: "sessor@email.co.uk", tradingAddress: "6 Unit Business Park Town", telephoneNumber: "00000000073" },
                                 companyName: "EPC R Us Ltd",
                                 status: "Registered",
                                 firstName: "Someone",
                                 lastName: "Person",
                                 registeredBy: { name: "test scheme", schemeId: scheme_id } },
                              ownerCommissionReport: "Y",
                              delegatedPersonCommissionReport: "N",
                              delegatedProtocolDate: nil,
                              delegatedProtocolSetUp: nil,
                              propertyType: {
                                propertyTypeShortDescription: "General Industrial",
                                propertyTypeLongDescription: "B2 to B7 General Industrial and Special Industrial Groups",
                              },
                              buildingImprovements: "N",
                              operationalRatings: "Y",
                              dec: "N",
                              plannedCompletionDate: "2028-12-12",
                              actualCompletionDate: nil,
                              targetEmissionSavings: 1.61,
                              targetEnergySavings: 10.11,
                              acceptPrescriptiveImprovements: "Y",
                              prescriptiveImprovements:
                               [{ measureDescriptionShort: "Central time heating control", measureDescriptionLong: nil, measureValid: "N", measureType: nil },
                                { measureDescriptionShort: "Lighting controls", measureDescriptionLong: nil, measureValid: "Y", measureType: nil },
                                { measureDescriptionShort: "Draught-stripping windows and doors", measureDescriptionLong: nil, measureValid: "Y", measureType: nil },
                                { measureDescriptionShort: "Hot water storage insulation", measureDescriptionLong: nil, measureValid: "N", measureType: nil },
                                { measureDescriptionShort: "Lamp replacement", measureDescriptionLong: nil, measureValid: "N", measureType: nil },
                                { measureDescriptionShort: "Boiler replacement", measureDescriptionLong: nil, measureValid: "N", measureType: nil },
                                { measureDescriptionShort: "Roof insulation", measureDescriptionLong: nil, measureValid: "N", measureType: nil }],
                              alternativeImprovements: [],
                              addressId: "RRN-0000-0000-0000-0003-0000",
                              optOut: false,
                              relatedAssessments: [],
                              supersededBy: nil,
                              schemaType: "CS63-S-7.0",
                              countryName: "Scotland" }

        expect(response[:data]).to eq(expected_response)
      end
    end

    context "when requesting a Scottish DEC assessment" do
      before do
        dec_xml = Nokogiri.XML Samples.xml("DECAR-S-7.0", "dec")
        dec_xml
          .xpath("//*[local-name() = 'RRN']")
          .each do |node|
          node.content = "0000-0000-0000-0004-0000"
        end
        lodge_scottish_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "DECAR-S-7.0",
          migrated: true,
        )
      end

      it "returns the expected DEC" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0004-0000").body,
            symbolize_names: true,
          )

        expected_response = { assessmentId: "0000-0000-0000-0004-0000",
                              dateOfAssessment: "2023-06-27",
                              dateOfExpiry: "2026-03-18",
                              dateOfRegistration: "2023-06-27",
                              address:
                               { addressLine1: "Non-dom Property",
                                 addressLine2: "Buisness Park",
                                 addressLine3: "",
                                 addressLine4: "",
                                 town: "Town",
                                 postcode: "EH14 2SP" },
                              typeOfAssessment: "DEC",
                              schemaVersion: "7.0",
                              reportType: "1",
                              currentAssessment: { date: "2025-03-19", energyEfficiencyRating: 36, energyEfficiencyBand: "b", heatingCo2: 0, electricityCo2: 14, renewablesCo2: 0 },
                              year1Assessment: { date: "2024-03-01", energyEfficiencyRating: 33, energyEfficiencyBand: "b", heatingCo2: 5, electricityCo2: 17, renewablesCo2: 0 },
                              year2Assessment: { date: "2023-03-01", energyEfficiencyRating: 33, energyEfficiencyBand: "b", heatingCo2: 5, electricityCo2: 17, renewablesCo2: 0 },
                              technicalInformation:
                               { mainHeatingFuel: "Natural Gas",
                                 buildingEnvironment: "Heating and Natural Ventilation",
                                 floorArea: 1194.47,
                                 occupier: "Industrial Estate",
                                 assetRating: 46,
                                 annualEnergyUseFuelThermal: 2,
                                 annualEnergyUseElectrical: 22,
                                 typicalThermalUse: 68,
                                 typicalElectricalUse: 35,
                                 renewablesFuelThermal: 0,
                                 renewablesElectrical: 0 },
                              assessor:
                               { schemeAssessorId: "SPEC000000",
                                 companyDetails: { name: "EPC R Us Ltd", address: "6 Unit Business Park Town" },
                                 contactDetails: { email: "assessor@co.uk", telephoneNumber: "000002828282" },
                                 firstName: "Someone",
                                 lastName: "Person",
                                 registeredBy: { name: "test scheme", schemeId: scheme_id } },
                              administrativeInformation: { issueDate: "2023-06-27", calculationTool: "BSD, OR Scotland, v1.0.3", relatedPartyDisclosure: "1" },
                              relatedRrn: nil,
                              addressId: "RRN-0000-0000-0000-0004-0000",
                              optOut: false,
                              relatedAssessments: [],
                              supersededBy: nil,
                              schemaType: "DECAR-S-7.0",
                              countryName: "Scotland" }

        expect(response[:data]).to eq(expected_response)
      end
    end

    context "when requesting a Scottish DEC-AR assessment" do
      before do
        dec_ar_xml = Nokogiri.XML Samples.xml("DECAR-S-7.0", "dec-ar")
        dec_ar_xml
          .xpath("//*[local-name() = 'RRN']")
          .each do |node|
          node.content = "0000-0000-0000-0005-0000"
        end
        lodge_scottish_assessment(
          assessment_body: dec_ar_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "DECAR-S-7.0",
          migrated: true,
        )
      end

      it "returns the expected DEC-AR" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0005-0000").body,
            symbolize_names: true,
          )

        expected_response = { typeOfAssessment: "DEC-AR",
                              assessmentId: "0000-0000-0000-0005-0000",
                              reportType: "2",
                              dateOfAssessment: "2023-06-27",
                              dateOfRegistration: "2023-06-27",
                              dateOfExpiry: "2033-06-26",
                              address:
                               { addressLine1: "Non-dom Property",
                                 addressLine2: "Buisness Park",
                                 addressLine3: "",
                                 addressLine4: "",
                                 town: "Town",
                                 postcode: "EH14 2SP" },
                              assessor:
                               { schemeAssessorId: "SPEC000000",
                                 companyDetails: { name: "EPC R Us Ltd", address: "6 Unit Business Park Town" },
                                 contactDetails: { email: "assessor@co.uk", telephoneNumber: "000002828282" },
                                 firstName: "Someone",
                                 lastName: "Person",
                                 registeredBy: { name: "test scheme", schemeId: scheme_id } },
                              shortPaybackRecommendations:
                               [{ code: "X24", text: "Boiler plant should be regularly tested and adjusted by experts for optimum operating efficiency.", cO2Impact: "MEDIUM" },
                                { code: "X15",
                                  text: "Consider engaging with building users to economise equipment energy consumption with targets, guidance on their achievement and incentives.",
                                  cO2Impact: "HIGH" },
                                { code: "X25",
                                  text:
                                   "Consider introducing a system of regular checks of Heating, Ventilation and Air Conditioning (HVAC) time and temperature settings and provisions to prevent unauthorised adjustment.",
                                  cO2Impact: "MEDIUM" },
                                { code: "SP24", text: "Enable power save settings and power down management on computers and associated equipment.", cO2Impact: "MEDIUM" },
                                { code: "SP3",
                                  text:
                                   "Consider installing automated controls and monitoring systems to electrical equipment and portable appliances to minimise electricity waste.",
                                  cO2Impact: "LOW" },
                                { code: "X9",
                                  text:
                                   "Engage experts to assess the air conditioning systems in accordance with CIBSE TM 44.  (This could be an appropriate opportunity to engage an accredited energy Assessor to undertake an inspection in compliance with the Energy Performance of Buildings Regulations).",
                                  cO2Impact: "MEDIUM" },
                                { code: "X10",
                                  text: "Engage experts to propose and set up an air conditioning servicing and maintenance regime and implement it.",
                                  cO2Impact: "MEDIUM" },
                                { code: "CON10", text: "Seek to minimise simultaneous operation of heating and cooling systems.", cO2Impact: "HIGH" },
                                { code: "AC12",
                                  text: "Engage experts to survey the air conditioning systems and propose remedial works to improve condition and operating efficiency.",
                                  cO2Impact: "MEDIUM" },
                                { code: "SP14",
                                  text:
                                   "Consider with experts implementation of an energy efficient equipment procurement regime that will upgrade existing equipment and renew in a planned cost-effective programme.",
                                  cO2Impact: "MEDIUM" },
                                { code: "OM15",
                                  text:
                                   "It is recommended that energy management techniques are introduced.  These could include efforts to gain building users commitment to save energy, allocating responsibility for energy to a specific person (champion), setting targets and monitoring.",
                                  cO2Impact: "HIGH" }],
                              mediumPaybackRecommendations:
                               [{ code: "AC9",
                                  text:
                                   "Engage experts to assess condensers location and cleansing regime and propose recommendations to improve effectiveness and energy efficiency.",
                                  cO2Impact: "MEDIUM" },
                                { code: "HW19", text: "Engage experts to propose specific measures to reduce hot water wastage and plan to carry this out. ", cO2Impact: "LOW" },
                                { code: "BF9", text: "Consider introducing or improving cavity wall insulation.", cO2Impact: "MEDIUM" },
                                { code: "X3",
                                  text:
                                   "Consider implementing regular inspections of the building fabric to check on the condition of insulation and sealing measures and removal of accidental ventilation paths.",
                                  cO2Impact: "MEDIUM" }],
                              longPaybackRecommendations:
                               [{ code: "X1",
                                  text:
                                   "The current metering provisions do not enable production of a specific and reasonably accurate Operational Rating for this building.  It is recommended that meters be installed and a regime of recording data be put in place.  CIBSE TM 39 gives guidance on this.",
                                  cO2Impact: "LOW" }],
                              otherPaybackRecommendations:
                               [{ code: "None",
                                  text:
                                   "There is no seperate electricity metering within the building and thus pro-rata sharing of metered usage may not represent actual usage. Monitoring and bench marking of usage is not possible and therefore improvements in energy efficiency are difficult to quantify.",
                                  cO2Impact: "LOW" }],
                              technicalInformation:
                               { buildingEnvironment: "Mixed-mode with Natural Ventilation",
                                 floorArea: 178.3,
                                 occupier: "Business name",
                                 propertyType: "General office",
                                 renewableSources: nil,
                                 discountedEnergy: nil,
                                 inspectionType: "Physical" },
                              administrativeInformation: {
                                issueDate: "2023-06-27",
                                calculationTool: "BSD, OR Scotland, v1.0.1",
                              },
                              siteServiceOne: { description: "Electricity", quantity: 26_914 },
                              siteServiceTwo: { description: "Natural Gas", quantity: 1204 },
                              siteServiceThree: { description: "Not used", quantity: 0 },
                              relatedRrn: nil,
                              addressId: "RRN-0000-0000-0000-0005-0000",
                              optOut: false,
                              relatedAssessments: [],
                              supersededBy: nil,
                              schemaType: "DECAR-S-7.0",
                              countryName: "Scotland" }

        expect(response[:data]).to eq(expected_response)
      end
    end

    context "when requesting a Scottish DEC or DEC-AR assessment from a dual lodgement" do
      before do
        dual_xml = Nokogiri.XML Samples.xml("DECAR-S-7.0", "dec+ar")

        lodge_scottish_assessment(
          assessment_body: dual_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "DECAR-S-7.0",
          migrated: true,
        )
      end

      it "returns the expected DEC-AR" do
        response =
          JSON.parse(
            fetch_scottish_certificate_summary(id: "0000-0000-0000-0000-0050").body,
            symbolize_names: true,
          )

        expected_response = { typeOfAssessment: "DEC-AR",
                              assessmentId: "0000-0000-0000-0000-0050",
                              reportType: "2",
                              dateOfAssessment: "2023-06-27",
                              dateOfExpiry: "2033-06-26",
                              dateOfRegistration: "2023-06-27",
                              address: { addressLine1: "Non-dom Property", addressLine2: "Buisness Park", addressLine3: "", addressLine4: "", town: "Town", postcode: "EH14 2SP" },
                              assessor:
                               { schemeAssessorId: "SPEC000000",
                                 contactDetails: { email: "assessor@co.uk", telephoneNumber: "000002828282" },
                                 companyDetails: { name: "EPC R Us Ltd", address: "6 Unit Business Park Town" },
                                 firstName: "Someone",
                                 lastName: "Person",
                                 registeredBy: { name: "test scheme", schemeId: scheme_id } },
                              shortPaybackRecommendations:
                               [{ code: "X12",
                                  text: "Clean windows and roof lights to maximise daylight entering building and reduce the need for artificial lighting.",
                                  cO2Impact: "MEDIUM" },
                                { code: "X11",
                                  text: "Consider implementing a programme of planned lighting systems maintenance to maintain effectiveness and energy efficiency.",
                                  cO2Impact: "MEDIUM" },
                                { code: "X9",
                                  text:
                                   "Engage experts to assess the air conditioning systems in accordance with CIBSE TM 44.  (This could be an appropriate opportunity to engage an accredited energy Assessor to undertake an inspection in compliance with the Energy Performance of Buildings Regulations).",
                                  cO2Impact: "HIGH" },
                                { code: "X10",
                                  text: "Engage experts to propose and set up an air conditioning servicing and maintenance regime and implement it.",
                                  cO2Impact: "HIGH" },
                                { code: "OM15",
                                  text:
                                   "It is recommended that energy management techniques are introduced.  These could include efforts to gain building users commitment to save energy, allocating responsibility for energy to a specific person (champion), setting targets and monitoring.",
                                  cO2Impact: "MEDIUM" },
                                { code: "BF6",
                                  text:
                                   "Consider how building fabric air tightness could be improved, for example sealing, draught stripping and closing off unused ventilation openings, chimneys.",
                                  cO2Impact: "MEDIUM" },
                                { code: "AC12",
                                  text: "Engage experts to survey the air conditioning systems and propose remedial works to improve condition and operating efficiency.",
                                  cO2Impact: "HIGH" }],
                              mediumPaybackRecommendations:
                               [{ code: "X3",
                                  text:
                                   "Consider implementing regular inspections of the building fabric to check on the condition of insulation and sealing measures and removal of accidental ventilation paths.",
                                  cO2Impact: "MEDIUM" },
                                { code: "BF9", text: "Consider introducing or improving cavity wall insulation.", cO2Impact: "MEDIUM" },
                                { code: "AC9",
                                  text:
                                   "Engage experts to assess condensers location and cleansing regime and propose recommendations to improve effectiveness and energy efficiency.",
                                  cO2Impact: "HIGH" },
                                { code: "BF22",
                                  text:
                                   "Consider engaging experts to review the condition of the building fabric and propose measures to improve energy performance.  This might include building pressure tests for air tightness and thermography tests for insulation continuity.",
                                  cO2Impact: "MEDIUM" }],
                              longPaybackRecommendations:
                               [{ code: "X13",
                                  text:
                                   "Engage experts to review the building lighting strategies and propose alterations and/or upgrades to daylighting provisions, luminaires and their control systems and an implementation plan.",
                                  cO2Impact: "MEDIUM" },
                                { code: "X1",
                                  text:
                                   "The current metering provisions do not enable production of a specific and reasonably accurate Operational Rating for this building.  It is recommended that meters be installed and a regime of recording data be put in place.  CIBSE TM 39 gives guidance on this.",
                                  cO2Impact: "HIGH" },
                                { code: "BF3", text: "Consider replacing or improving glazing.", cO2Impact: "MEDIUM" }],
                              otherPaybackRecommendations: [],
                              technicalInformation:
                               { buildingEnvironment: "Heating and Natural Ventilation",
                                 floorArea: 973.6,
                                 occupier: "Business Name",
                                 propertyType: "General office",
                                 renewableSources: nil,
                                 discountedEnergy: nil,
                                 inspectionType: "Physical" },
                              administrativeInformation: { issueDate: "2023-06-27", calculationTool: "BSD, OR Scotland, v1.0.0" },
                              siteServiceOne: { description: "Natural Gas", quantity: 76_639 },
                              siteServiceTwo: { description: "Electricity", quantity: 36_419 },
                              siteServiceThree: { description: "Not used", quantity: 0 },
                              relatedRrn: "0000-0000-0000-0000-0040",
                              addressId: "RRN-0000-0000-0000-0000-0050",
                              optOut: false,
                              relatedAssessments: [],
                              supersededBy: nil,
                              schemaType: "DECAR-S-7.0",
                              countryName: "Scotland",
                              energyBandFromRelatedCertificate: "b" }

        expect(response[:data]).to eq(expected_response)
      end
    end
  end
end
