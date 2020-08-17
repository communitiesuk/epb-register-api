# frozen_string_literal: true

require "date"

describe "Acceptance::Assessment" do
  include RSpecRegisterApiServiceMixin
  class GreenDealPlans < ActiveRecord::Base; end

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:green_deal_plan_stub) { GreenDealPlansGatewayStub.new }

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  let(:sanitised_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/sanitised/sap.xml"
  end

  def expected_sap_response(scheme_id)
    {
      assessor: {
        schemeAssessorId: "SPEC000000",
        registeredBy: { schemeId: scheme_id, name: "test scheme" },
        firstName: "Someone",
        middleNames: "Muddle",
        lastName: "Person",
        dateOfBirth: "1991-02-25",
        contactDetails: {
          telephoneNumber: "010199991010101", email: "person@person.com"
        },
        searchResultsComparisonPostcode: "",
        address: {},
        companyDetails: {},
        qualifications: {
          domesticRdSap: "INACTIVE",
          domesticSap: "ACTIVE",
          nonDomesticSp3: "INACTIVE",
          nonDomesticCc4: "INACTIVE",
          nonDomesticDec: "INACTIVE",
          nonDomesticNos3: "INACTIVE",
          nonDomesticNos4: "INACTIVE",
          nonDomesticNos5: "INACTIVE",
          gda: "INACTIVE",
        },
      },
      dateOfAssessment: "2020-05-04",
      dateRegistered: "2020-05-04",
      tenure: "1",
      totalFloorArea: 10.0,
      typeOfAssessment: "SAP",
      dwellingType: "Dwelling-Type0",
      assessmentId: "0000-0000-0000-0000-0000",
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
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "walls",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "walls",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "roof",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "roof",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "floor",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "floor",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "windows",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "main_heating",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "main_heating",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "main_heating_controls",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "main_heating_controls",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "secondary_heating",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "hot_water",
        },
        {
          energyEfficiencyRating: 0,
          environmentalEfficiencyRating: 0,
          name: "lighting",
        },
      ],
      propertyAgeBand: "1750",
      recommendedImprovements: [
        {
          energyPerformanceRatingImprovement: 50,
          environmentalImpactRatingImprovement: 50,
          greenDealCategoryCode: "1",
          improvementCategory: "6",
          improvementCode: "5",
          improvementDescription: nil,
          improvementTitle: nil,
          improvementType: "Z3",
          indicativeCost: "5",
          sequence: 0,
          typicalSaving: "0.0",
        },
        {
          energyPerformanceRatingImprovement: 60,
          environmentalImpactRatingImprovement: 64,
          greenDealCategoryCode: "3",
          improvementCategory: "2",
          improvementCode: "1",
          improvementDescription: nil,
          improvementTitle: nil,
          improvementType: "Z2",
          indicativeCost: "2",
          sequence: 1,
          typicalSaving: "0.1",
        },
      ],
      status: "ENTERED",
      relatedAssessments: [
        {
          assessmentExpiryDate: "2030-05-04",
          assessmentId: "0000-0000-0000-0000-0000",
          assessmentStatus: "ENTERED",
          assessmentType: "SAP",
        },
      ],
    }
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
    let(:response) do
      JSON.parse fetch_assessment("9999-9999-9999-9999-9999", [404]).body
    end

    it "returns status 404 for a get" do
      fetch_assessment("9999-9999-9999-9999-9999", [404])
    end

    it "returns an error message structure" do
      expect(response).to eq(
        {
          "errors" => [
            { "code" => "NOT_FOUND", "title" => "Assessment not found" },
          ],
        },
      )
    end
  end

  context "when the assessment ID is badly formatted" do
    let(:response) { JSON.parse fetch_assessment("NOT-AN-RRN", [400]).body }

    it "returns status 400 for a get" do
      fetch_assessment("NOT-AN-RRN", [400])
    end

    it "returns an error message structure" do
      expect(response).to eq(
        {
          "errors" => [
            {
              "code" => "INVALID_REQUEST",
              "title" => "The requested assessment id is not valid",
            },
          ],
        },
      )
    end
  end

  context "when a domestic assessment exists" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:response) do
      JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE")

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-18.0.0"
    end

    it "returns the assessment details" do
      expect(response["data"]).to eq(
        JSON.parse(expected_sap_response(scheme_id).to_json),
      )
    end

    it "can be fetched using the 20 digit RRN without hyphens" do
      response_body = JSON.parse fetch_assessment("00000000000000000000").body
      expect(response_body["data"]).to eq(
        JSON.parse(expected_sap_response(scheme_id).to_json),
      )
    end

    context "when a domestic assessment has a green deal plan" do
      let(:response) do
        JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
      end

      it "returns the assessment details with the green deal plan" do
        green_deal_plan_stub.create_green_deal_plan("0000-0000-0000-0000-0000")

        green_deal_plan = {
          greenDealPlanId: "ABC123456DEF",
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
            { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
            { fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9 },
            { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
          ],
          estimatedSavings: 1566,
        }

        sap_response = expected_sap_response(scheme_id)

        expected_response =
          JSON.parse(sap_response.merge(greenDealPlan: green_deal_plan).to_json)
        expect(response["data"]).to eq(expected_response)
      end
    end

    context "when requesting an assessments XML" do
      let(:response) do
        fetch_assessment "0000-0000-0000-0000-0000",
                         headers: { "Accept": "application/xml" }
      end

      it "returns the XML as expected" do
        expect(
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + response.body,
        ).to eq(sanitised_sap_xml)
      end
    end

    context "when a certificate has related certificates" do
      let(:assessment) { Nokogiri.XML valid_sap_xml }
      let(:address_id) { assessment.at "UPRN" }
      let(:assessment_id) { assessment.at "RRN" }
      let(:assessment_date) { assessment.at "Inspection-Date" }

      let(:response) do
        JSON.parse fetch_assessment("0000-0000-0000-0000-0000").body
      end

      let(:expected_response) do
        JSON.parse expected_sap_response(scheme_id).to_json
      end

      before do
        address_id.children = "RRN-0000-0000-0000-0000-0000"
        assessment_id.children = "1234-3453-6245-2473-5623"
        assessment_date.children = "2010-05-05"

        lodge_assessment assessment_body: assessment.to_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "SAP-Schema-18.0.0"

        expected_response["relatedAssessments"] = [
          {
            "assessmentExpiryDate" => "2030-05-04",
            "assessmentId" => "0000-0000-0000-0000-0000",
            "assessmentStatus" => "ENTERED",
            "assessmentType" => "SAP",
          },
          {
            "assessmentExpiryDate" => "2020-05-05",
            "assessmentId" => "1234-3453-6245-2473-5623",
            "assessmentStatus" => "EXPIRED",
            "assessmentType" => "SAP",
          },
        ]
      end

      it "returns all the related certificates" do
        expect(response["data"]).to eq(expected_response)
      end
    end
  end
end
