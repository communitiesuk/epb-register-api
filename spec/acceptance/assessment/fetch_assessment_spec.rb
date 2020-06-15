# frozen_string_literal: true

require "date"

describe "Acceptance::Assessment" do
  include RSpecAssessorServiceMixin
  class GreenDealPlans < ActiveRecord::Base; end

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  let(:sanitised_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/sap.xml"
  end

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticRdSap: "ACTIVE",
        domesticSap: "INACTIVE",
        nonDomesticSp3: "INACTIVE",
        nonDomesticCc4: "INACTIVE",
        nonDomesticDec: "INACTIVE",
        nonDomesticNos3: "INACTIVE",
        nonDomesticNos4: "STRUCKOFF",
        nonDomesticNos5: "SUSPENDED",
        gda: "INACTIVE",
      },
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
      totalFloorArea: 1_000.45,
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
        currentSpaceHeatingDemand: 222.23,
        currentWaterHeatingDemand: 321.14,
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
        {
          sequence: 1,
          indicativeCost: "£200 - £4,000",
          typicalSaving: 400.21,
          improvementCategory: "string",
          improvementType: "string",
          improvementTitle: "Some improvement",
          improvementDescription: "Some improvement description",
          energyPerformanceRatingImprovement: 80,
          environmentalImpactRatingImprovement: 90,
          greenDealCategoryCode: "string",
        },
      ],
      propertySummary: [
        {
          description: "Description0",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Wall",
        },
        {
          description: "Description1",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Wall",
        },
        {
          description: "Description2",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Roof",
        },
        {
          description: "Description3",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Roof",
        },
        {
          description: "Description4",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Floor",
        },
        {
          description: "Description5",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Floor",
        },
        {
          description: "Description6",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Window",
        },
        {
          description: "Description7",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Main_Heating",
        },
        {
          description: "Description8",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Main_Heating",
        },
        {
          description: "Description9",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Main_Heating_Controls",
        },
        {
          description: "Description10",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Main_Heating_Controls",
        },
        {
          description: "Description11",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Hot_Water",
        },
        {
          description: "Description12",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Lighting",
        },
        {
          description: "Description13",
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "Secondary_Heating",
        },
      ],
      relatedPartyDisclosureNumber: nil,
      relatedPartyDisclosureText: "married to owner",
    }.freeze
  end

  let(:second_valid_assessment_body) do
    {
      schemeAssessorId: "TEST000007",
      dateOfAssessment: "2020-01-13",
      dateRegistered: "2020-01-13",
      totalFloorArea: 1_000.45,
      typeOfAssessment: "RdSAP",
      dwellingType: "Top floor flat",
      currentEnergyEfficiencyRating: 75,
      potentialEnergyEfficiencyRating: 80,
      currentCarbonEmission: 2.4,
      potentialCarbonEmission: 1.4,
      optOut: true,
      postcode: "SE1 7EZ",
      dateOfExpiry: "2021-01-01",
      addressLine1: "Flat 33",
      addressLine2: "18 Palmtree Road",
      addressLine3: "",
      addressLine4: "",
      town: "Brighton",
      heatDemand: {
        currentSpaceHeatingDemand: 222.23,
        currentWaterHeatingDemand: 321.14,
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
        {
          sequence: 1,
          indicativeCost: "£200 - £4,000",
          typicalSaving: 400.21,
          improvementCategory: "string",
          improvementType: "string",
          improvementTitle: "Some improvement",
          improvementDescription: "Some improvement description",
          energyPerformanceRatingImprovement: 80,
          environmentalImpactRatingImprovement: 90,
          greenDealCategoryCode: "string",
        },
      ],
      propertySummary: [],
      relatedPartyDisclosureNumber: 1,
      relatedPartyDisclosureText: nil,
    }.freeze
  end

  def assessment_without(key)
    assessment = valid_assessment_body.dup
    assessment.delete(key)
    assessment
  end

  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_assessment("123", [401], false)
    end

    it "rejects a request with the wrong scopes" do
      fetch_assessment("124", [403], true, {}, %w[wrong:scope])
    end
  end

  context "when a domestic assessment doesnt exist" do
    it "returns status 404 for a get" do
      fetch_assessment("DOESNT-EXIST", [404])
    end

    it "returns an error message structure" do
      response_body = fetch_assessment("DOESNT-EXIST", [404]).body
      expect(JSON.parse(response_body)).to eq(
        {
          "errors" => [
            { "code" => "NOT_FOUND", "title" => "Assessment not found" },
          ],
        },
      )
    end
  end

  context "when a domestic assessment exists" do
    it "returns a 200" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)
      migrate_assessment("15650-651625-18267167", valid_assessment_body, [200])

      response = fetch_assessment("15650-651625-18267167")
      expect(response.status).to eq(200)
    end

    it "returns the assessment details" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)
      migrate_assessment("15650-651625-18267167", valid_assessment_body)

      response = JSON.parse(fetch_assessment("15650-651625-18267167").body)

      expected_response =
        JSON.parse(
          {
            assessor: {
              schemeAssessorId: valid_assessment_body[:schemeAssessorId],
              registeredBy: { schemeId: scheme_id, name: "test scheme" },
              firstName: valid_assessor_request_body[:firstName],
              middleNames: valid_assessor_request_body[:middleNames],
              lastName: valid_assessor_request_body[:lastName],
              dateOfBirth: valid_assessor_request_body[:dateOfBirth],
              contactDetails: {
                telephoneNumber:
                  valid_assessor_request_body[:contactDetails][
                    :telephoneNumber
                  ],
                email: valid_assessor_request_body[:contactDetails][:email],
              },
              searchResultsComparisonPostcode: "",
              address: {},
              companyDetails: {},
              qualifications: {
                domesticSap: "INACTIVE",
                domesticRdSap: "ACTIVE",
                nonDomesticSp3: "INACTIVE",
                nonDomesticCc4: "INACTIVE",
                nonDomesticDec: "INACTIVE",
                nonDomesticNos3: "INACTIVE",
                nonDomesticNos4: "STRUCKOFF",
                nonDomesticNos5: "SUSPENDED",
                gda: "INACTIVE",
              },
            },
            dateOfAssessment: valid_assessment_body[:dateOfAssessment],
            dateRegistered: valid_assessment_body[:dateRegistered],
            totalFloorArea: valid_assessment_body[:totalFloorArea],
            typeOfAssessment: valid_assessment_body[:typeOfAssessment],
            dwellingType: valid_assessment_body[:dwellingType],
            assessmentId: "15650-651625-18267167",
            currentEnergyEfficiencyRating:
              valid_assessment_body[:currentEnergyEfficiencyRating],
            potentialEnergyEfficiencyRating:
              valid_assessment_body[:potentialEnergyEfficiencyRating],
            currentCarbonEmission:
              valid_assessment_body[:currentCarbonEmission],
            potentialCarbonEmission:
              valid_assessment_body[:potentialCarbonEmission],
            currentEnergyEfficiencyBand: "c",
            potentialEnergyEfficiencyBand: "c",
            optOut: false,
            postcode: valid_assessment_body[:postcode],
            dateOfExpiry: valid_assessment_body[:dateOfExpiry],
            town: valid_assessment_body[:town],
            addressId: nil,
            addressLine1: valid_assessment_body[:addressLine1],
            addressLine2: valid_assessment_body[:addressLine2],
            addressLine3: valid_assessment_body[:addressLine4],
            addressLine4: valid_assessment_body[:addressLine4],
            heatDemand: {
              currentSpaceHeatingDemand:
                valid_assessment_body[:heatDemand][:currentSpaceHeatingDemand],
              currentWaterHeatingDemand:
                valid_assessment_body[:heatDemand][:currentWaterHeatingDemand],
              impactOfLoftInsulation:
                valid_assessment_body[:heatDemand][:impactOfLoftInsulation],
              impactOfCavityInsulation:
                valid_assessment_body[:heatDemand][:impactOfCavityInsulation],
              impactOfSolidWallInsulation:
                valid_assessment_body[:heatDemand][:impactOfSolidWallInsulation],
            },
            recommendedImprovements: [
              {
                sequence: 0,
                improvementCode: "1",
                indicativeCost: "£200 - £4,000",
                typicalSaving: "400.21",
                improvementCategory: "string",
                improvementType: "string",
                improvementTitle: nil,
                improvementDescription: nil,
                energyPerformanceRatingImprovement: 80,
                environmentalImpactRatingImprovement: 90,
                greenDealCategoryCode: "string",
              },
              {
                sequence: 1,
                improvementCode: nil,
                indicativeCost: "£200 - £4,000",
                typicalSaving: "400.21",
                improvementCategory: "string",
                improvementType: "string",
                improvementTitle: "Some improvement",
                improvementDescription: "Some improvement description",
                energyPerformanceRatingImprovement: 80,
                environmentalImpactRatingImprovement: 90,
                greenDealCategoryCode: "string",
              },
            ],
            propertySummary: valid_assessment_body[:propertySummary],
            relatedPartyDisclosureNumber:
              valid_assessment_body[:relatedPartyDisclosureNumber],
            relatedPartyDisclosureText:
              valid_assessment_body[:relatedPartyDisclosureText],
          }.to_json,
        )
      expect(response["data"]).to eq(expected_response)
    end

    context "when a domestic assessment has a green deal plan" do
      it "returns the assessment details with the green deal plan" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)
        migrate_assessment("15650-651625-18267167", valid_assessment_body)
        create_green_deal_plan("15650-651625-18267167")

        response = JSON.parse(fetch_assessment("15650-651625-18267167").body)

        expected_response =
          JSON.parse(
            {
              assessor: {
                schemeAssessorId: valid_assessment_body[:schemeAssessorId],
                registeredBy: { schemeId: scheme_id, name: "test scheme" },
                firstName: valid_assessor_request_body[:firstName],
                middleNames: valid_assessor_request_body[:middleNames],
                lastName: valid_assessor_request_body[:lastName],
                dateOfBirth: valid_assessor_request_body[:dateOfBirth],
                contactDetails: {
                  telephoneNumber:
                    valid_assessor_request_body[:contactDetails][
                      :telephoneNumber
                    ],
                  email: valid_assessor_request_body[:contactDetails][:email],
                },
                searchResultsComparisonPostcode: "",
                address: {},
                companyDetails: {},
                qualifications: {
                  domesticSap: "INACTIVE",
                  domesticRdSap: "ACTIVE",
                  nonDomesticSp3: "INACTIVE",
                  nonDomesticCc4: "INACTIVE",
                  nonDomesticDec: "INACTIVE",
                  nonDomesticNos3: "INACTIVE",
                  nonDomesticNos4: "STRUCKOFF",
                  nonDomesticNos5: "SUSPENDED",
                  gda: "INACTIVE",
                },
              },
              dateOfAssessment: valid_assessment_body[:dateOfAssessment],
              dateRegistered: valid_assessment_body[:dateRegistered],
              totalFloorArea: valid_assessment_body[:totalFloorArea],
              typeOfAssessment: valid_assessment_body[:typeOfAssessment],
              dwellingType: valid_assessment_body[:dwellingType],
              assessmentId: "15650-651625-18267167",
              currentEnergyEfficiencyRating:
                valid_assessment_body[:currentEnergyEfficiencyRating],
              potentialEnergyEfficiencyRating:
                valid_assessment_body[:potentialEnergyEfficiencyRating],
              currentCarbonEmission:
                valid_assessment_body[:currentCarbonEmission],
              potentialCarbonEmission:
                valid_assessment_body[:potentialCarbonEmission],
              currentEnergyEfficiencyBand: "c",
              potentialEnergyEfficiencyBand: "c",
              optOut: false,
              postcode: valid_assessment_body[:postcode],
              dateOfExpiry: valid_assessment_body[:dateOfExpiry],
              town: valid_assessment_body[:town],
              addressId: nil,
              addressLine1: valid_assessment_body[:addressLine1],
              addressLine2: valid_assessment_body[:addressLine2],
              addressLine3: valid_assessment_body[:addressLine4],
              addressLine4: valid_assessment_body[:addressLine4],
              heatDemand: {
                currentSpaceHeatingDemand:
                  valid_assessment_body[:heatDemand][
                    :currentSpaceHeatingDemand
                  ],
                currentWaterHeatingDemand:
                  valid_assessment_body[:heatDemand][
                    :currentWaterHeatingDemand
                  ],
                impactOfLoftInsulation:
                  valid_assessment_body[:heatDemand][:impactOfLoftInsulation],
                impactOfCavityInsulation:
                  valid_assessment_body[:heatDemand][:impactOfCavityInsulation],
                impactOfSolidWallInsulation:
                  valid_assessment_body[:heatDemand][
                    :impactOfSolidWallInsulation
                  ],
              },
              recommendedImprovements: [
                {
                  sequence: 0,
                  improvementCode: "1",
                  indicativeCost: "£200 - £4,000",
                  typicalSaving: "400.21",
                  improvementCategory: "string",
                  improvementType: "string",
                  improvementTitle: nil,
                  improvementDescription: nil,
                  energyPerformanceRatingImprovement: 80,
                  environmentalImpactRatingImprovement: 90,
                  greenDealCategoryCode: "string",
                },
                {
                  sequence: 1,
                  improvementCode: nil,
                  indicativeCost: "£200 - £4,000",
                  typicalSaving: "400.21",
                  improvementCategory: "string",
                  improvementType: "string",
                  improvementTitle: "Some improvement",
                  improvementDescription: "Some improvement description",
                  energyPerformanceRatingImprovement: 80,
                  environmentalImpactRatingImprovement: 90,
                  greenDealCategoryCode: "string",
                },
              ],
              propertySummary: valid_assessment_body[:propertySummary],
              relatedPartyDisclosureNumber:
                valid_assessment_body[:relatedPartyDisclosureNumber],
              relatedPartyDisclosureText:
                valid_assessment_body[:relatedPartyDisclosureText],
              greenDealPlan: {
                greenDealPlanId: "ABC123456DEF",
                assessmentId: "15650-651625-18267167",
                startDate: "2020-01-30",
                endDate: "2030-02-28",
                providerDetails: {
                  name: "The Bank",
                  telephone: "0800 0000000",
                  email: "lender@example.com",
                },
                interest: { rate: nil, fixed: true },
                chargeUplift: { amount: nil, date: "2030-02-28" },
                ccaRegulated: nil,
                structureChanged: nil,
                measuresRemoved: nil,
                measures: [
                  {
                    measureType: "Loft insulation",
                    product: "WarmHome lagging stuff (TM)",
                    repaidDate: "2025-03-29",
                  },
                ],
                charges: [
                  {
                    startDate: "2020-03-29",
                    endDate: "2030-03-29",
                    dailyCharge: "0.34",
                  },
                ],
                savings: [
                  {
                    fuelCode: "LPG", fuelSaving: 0, standingChargeFraction: -0.3
                  },
                ],
              },
            }.to_json,
          )
        expect(response["data"]).to eq(expected_response)
      end
    end

    context "when requesting an assessments XML" do
      it "returns the XML as expected" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
        )

        lodge_assessment assessment_body: valid_sap_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "SAP-Schema-17.1",
                         headers: { "Accept": "application/xml" }

        response =
          fetch_assessment "0000-0000-0000-0000-0000",
                           headers: { "Accept": "application/xml" }

        expect(
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + response.body,
        ).to eq(sanitised_sap_xml)
      end
    end

    context "when updating an existing assessment" do
      it "returns the assessment details" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)
        add_assessor(scheme_id, "TEST000007", valid_assessor_request_body)
        migrate_assessment("15650-651625-18267167", valid_assessment_body)
        migrate_assessment(
          "15650-651625-18267167",
          second_valid_assessment_body,
        )

        response = JSON.parse(fetch_assessment("15650-651625-18267167").body)

        expected_response =
          JSON.parse(
            {
              assessor: {
                schemeAssessorId:
                  second_valid_assessment_body[:schemeAssessorId],
                registeredBy: { schemeId: scheme_id, name: "test scheme" },
                firstName: valid_assessor_request_body[:firstName],
                middleNames: valid_assessor_request_body[:middleNames],
                lastName: valid_assessor_request_body[:lastName],
                dateOfBirth: valid_assessor_request_body[:dateOfBirth],
                contactDetails: {
                  telephoneNumber:
                    valid_assessor_request_body[:contactDetails][
                      :telephoneNumber
                    ],
                  email: valid_assessor_request_body[:contactDetails][:email],
                },
                searchResultsComparisonPostcode: "",
                address: {},
                companyDetails: {},
                qualifications: {
                  domesticSap: "INACTIVE",
                  domesticRdSap: "ACTIVE",
                  nonDomesticSp3: "INACTIVE",
                  nonDomesticCc4: "INACTIVE",
                  nonDomesticDec: "INACTIVE",
                  nonDomesticNos3: "INACTIVE",
                  nonDomesticNos4: "STRUCKOFF",
                  nonDomesticNos5: "SUSPENDED",
                  gda: "INACTIVE",
                },
              },
              dateOfAssessment: second_valid_assessment_body[:dateOfAssessment],
              dateRegistered: second_valid_assessment_body[:dateRegistered],
              totalFloorArea: second_valid_assessment_body[:totalFloorArea],
              typeOfAssessment: second_valid_assessment_body[:typeOfAssessment],
              dwellingType: second_valid_assessment_body[:dwellingType],
              assessmentId: "15650-651625-18267167",
              currentEnergyEfficiencyRating:
                second_valid_assessment_body[:currentEnergyEfficiencyRating],
              potentialEnergyEfficiencyRating:
                second_valid_assessment_body[:potentialEnergyEfficiencyRating],
              currentCarbonEmission:
                second_valid_assessment_body[:currentCarbonEmission],
              potentialCarbonEmission:
                second_valid_assessment_body[:potentialCarbonEmission],
              currentEnergyEfficiencyBand: "c",
              potentialEnergyEfficiencyBand: "c",
              optOut: true,
              postcode: second_valid_assessment_body[:postcode],
              dateOfExpiry: second_valid_assessment_body[:dateOfExpiry],
              town: second_valid_assessment_body[:town],
              addressId: nil,
              addressLine1: second_valid_assessment_body[:addressLine1],
              addressLine2: second_valid_assessment_body[:addressLine2],
              addressLine3: second_valid_assessment_body[:addressLine4],
              addressLine4: second_valid_assessment_body[:addressLine4],
              heatDemand: {
                currentSpaceHeatingDemand:
                  second_valid_assessment_body[:heatDemand][
                    :currentSpaceHeatingDemand
                  ],
                currentWaterHeatingDemand:
                  second_valid_assessment_body[:heatDemand][
                    :currentWaterHeatingDemand
                  ],
                impactOfLoftInsulation:
                  second_valid_assessment_body[:heatDemand][
                    :impactOfLoftInsulation
                  ],
                impactOfCavityInsulation:
                  second_valid_assessment_body[:heatDemand][
                    :impactOfCavityInsulation
                  ],
                impactOfSolidWallInsulation:
                  second_valid_assessment_body[:heatDemand][
                    :impactOfSolidWallInsulation
                  ],
              },
              recommendedImprovements: [
                {
                  sequence: 0,
                  improvementCode: "1",
                  indicativeCost: "£200 - £4,000",
                  typicalSaving: "400.21",
                  improvementCategory: "string",
                  improvementType: "string",
                  improvementTitle: nil,
                  improvementDescription: nil,
                  energyPerformanceRatingImprovement: 80,
                  environmentalImpactRatingImprovement: 90,
                  greenDealCategoryCode: "string",
                },
                {
                  sequence: 1,
                  improvementCode: nil,
                  indicativeCost: "£200 - £4,000",
                  typicalSaving: "400.21",
                  improvementCategory: "string",
                  improvementType: "string",
                  improvementTitle: "Some improvement",
                  improvementDescription: "Some improvement description",
                  energyPerformanceRatingImprovement: 80,
                  environmentalImpactRatingImprovement: 90,
                  greenDealCategoryCode: "string",
                },
              ],
              propertySummary: [],
              relatedPartyDisclosureNumber:
                second_valid_assessment_body[:relatedPartyDisclosureNumber],
              relatedPartyDisclosureText: nil,
            }.to_json,
          )
        expect(response["data"]).to eq(expected_response)
      end
    end
  end

  def create_green_deal_plan(assessment_id)
    GreenDealPlans.create(
      assessment_id: assessment_id,
      green_deal_plan_id: "ABC123456DEF",
      start_date: DateTime.new(2_020, 1, 30),
      end_date: DateTime.new(2_030, 2, 28),
      provider_name: "The Bank",
      provider_telephone: "0800 0000000",
      provider_email: "lender@example.com",
      fixed_interest_rate: true,
      charge_uplift_date: DateTime.new(2_030, 2, 28),
      measures: [
        {
          measureType: "Loft insulation",
          product: "WarmHome lagging stuff (TM)",
          repaidDate: "2025-03-29",
        },
      ],
      charges: [
        { startDate: "2020-03-29", endDate: "2030-03-29", dailyCharge: "0.34" },
      ],
      savings: [
        { fuelCode: "LPG", fuelSaving: 0, standingChargeFraction: -0.3 },
      ],
    )
  end
end
