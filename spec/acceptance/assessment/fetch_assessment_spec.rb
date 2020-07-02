# frozen_string_literal: true

require "date"

describe "Acceptance::Assessment" do
  include RSpecAssessorServiceMixin
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
      dateOfAssessment: "2006-05-04",
      dateRegistered: "2006-05-04",
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
      dateOfExpiry: "2016-05-04",
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
      estimatedCostForThreeYears: "689.83",
      potentialSavingForThreeYears: "174.83",
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
      propertyAgeBand: "K",
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
      relatedPartyDisclosureNumber: 1,
      relatedPartyDisclosureText: nil,
      status: "EXPIRED",
      relatedAssessments: [
        {
          assessmentExpiryDate: "2016-05-04",
          assessmentId: "0000-0000-0000-0000-0000",
          assessmentStatus: "EXPIRED",
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

      response = fetch_assessment("0000-0000-0000-0000-0000")
      expect(response.status).to eq(200)
    end

    it "returns the assessment details" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
      )

      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-17.1"

      response = JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)

      expected_response = JSON.parse(expected_sap_response(scheme_id).to_json)
      expect(response["data"]).to eq(expected_response)
    end

    context "when a domestic assessment has a green deal plan" do
      it "returns the assessment details with the green deal plan" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(domesticSap: "ACTIVE"),
        )

        lodge_assessment assessment_body: valid_sap_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "SAP-Schema-17.1"

        green_deal_plan_stub.create_green_deal_plan("0000-0000-0000-0000-0000")

        response = JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
        green_deal_plan = {
          greenDealPlanId: "ABC123456DEF",
          startDate: "30 January 2020",
          endDate: "28 February 2030",
          providerDetails: {
            name: "The Bank",
            telephone: "0800 0000000",
            email: "lender@example.com",
          },
          interest: { rate: nil, fixed: true },
          chargeUplift: { amount: nil, date: "28 February 2030" },
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
            { fuelCode: "LPG", fuelSaving: 0, standingChargeFraction: -0.3 },
          ],
        }

        sap_response = expected_sap_response(scheme_id)

        expected_response =
          JSON.parse(sap_response.merge(greenDealPlan: green_deal_plan).to_json)
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

    context "when a certificate has related certificates" do
      let(:expired_assessment) { Nokogiri.XML valid_sap_xml }

      let(:entered_assessment) { Nokogiri.XML valid_sap_xml }

      let(:response) { fetch_assessment("0000-0000-0000-0000-0000") }

      it "returns all the related certificates" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          "SPEC000000",
          AssessorStub.new.fetch_request_body(domesticSap: "ACTIVE"),
        )

        lodge_assessment assessment_body: expired_assessment.to_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "SAP-Schema-17.1"

        address_id = entered_assessment.at("UPRN")
        address_id.children = "RRN-0000-0000-0000-0000-0000"
        assessment_id = entered_assessment.at("RRN")
        assessment_id.children = "1234-3453-6245-2473-5623"
        assessment_date = entered_assessment.at("Inspection-Date")
        assessment_date.children = "2010-05-05"

        lodge_assessment assessment_body: entered_assessment.to_xml,
                         accepted_responses: [201],
                         auth_data: { scheme_ids: [scheme_id] },
                         schema_name: "SAP-Schema-17.1"

        response = JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)

        expected_response = JSON.parse(expected_sap_response(scheme_id).to_json)
        expected_response["relatedAssessments"] = [
          {
            "assessmentExpiryDate" => "2020-05-05",
            "assessmentId" => "1234-3453-6245-2473-5623",
            "assessmentStatus" => "EXPIRED",
            "assessmentType" => "SAP",
          },
          {
            "assessmentExpiryDate" => "2016-05-04",
            "assessmentId" => "0000-0000-0000-0000-0000",
            "assessmentStatus" => "EXPIRED",
            "assessmentType" => "SAP",
          },
        ]

        expect(response["data"]).to eq(expected_response)
      end
    end
  end
end
