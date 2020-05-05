# frozen_string_literal: true

describe "Acceptance::DomesticEnergyAssessment" do
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
      totalFloorArea: 1_000.45,
      typeOfAssessment: "RdSAP",
      dwellingType: "Top floor flat",
      addressSummary: "123 Victoria Street, London, SW1A 1BD",
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
      propertySummary: []
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
              qualifications: {
                domesticSap: "INACTIVE",
                domesticRdSap: "ACTIVE",
                nonDomesticSp3: "INACTIVE",
                nonDomesticCc4: "INACTIVE",
                nonDomesticDec: "INACTIVE",
                nonDomesticNos3: "INACTIVE",
                nonDomesticNos4: "INACTIVE",
                nonDomesticNos5: "INACTIVE",
              },
            },
            dateOfAssessment: valid_assessment_body[:dateOfAssessment],
            dateRegistered: valid_assessment_body[:dateRegistered],
            totalFloorArea: valid_assessment_body[:totalFloorArea],
            typeOfAssessment: valid_assessment_body[:typeOfAssessment],
            dwellingType: valid_assessment_body[:dwellingType],
            addressSummary: valid_assessment_body[:addressSummary],
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
            propertySummary: []
          }.to_json,
        )
      expect(response["data"]).to eq(expected_response)
    end
  end
end
