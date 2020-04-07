# frozen_string_literal: true

describe 'Acceptance::DomesticEnergyAssessment::SuggestedImprovements' do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: 'Someone',
      middleNames: 'Muddle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      searchResultsComparisonPostcode: '',
      qualifications: { domesticRdSap: 'ACTIVE' },
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      }
    }
  end

  let (:valid_recommendations) do
    [
      {
        sequence: 0,
        improvementCode: '1',
        indicativeCost: '£200 - £4,000',
        typicalSaving: 400.21,
        improvementCategory: 'string',
        improvementType: 'string',
        energyPerformanceRating: 'C',
        environmentalImpactRating: 'string',
        greenDealCategoryCode: 'string'
      },
      {
        sequence: 1,
        improvementCode: '2',
        indicativeCost: '£430 - £4,000',
        typicalSaving: 50.21,
        improvementCategory: 'string',
        improvementType: 'string',
        energyPerformanceRating: 'C',
        environmentalImpactRating: 'string',
        greenDealCategoryCode: 'string'
      }
    ]
  end

  let(:valid_assessment_body) do
    {
      schemeAssessorId: 'TEST123456',
      dateOfAssessment: '2020-01-13',
      dateRegistered: '2020-01-13',
      totalFloorArea: 1_000,
      typeOfAssessment: 'RdSAP',
      dwellingType: 'Top floor flat',
      addressSummary: '123 Victoria Street, London, SW1A 1BD',
      currentEnergyEfficiencyRating: 75,
      potentialEnergyEfficiencyRating: 80,
      postcode: 'SE1 7EZ',
      dateOfExpiry: '2021-01-01',
      addressLine1: 'Flat 33',
      addressLine2: '18 Palmtree Road',
      addressLine3: '',
      addressLine4: '',
      town: 'Brighton',
      heatDemand: {
        currentSpaceHeatingDemand: 222,
        currentWaterHeatingDemand: 321,
        impactOfLoftInsulation: 79,
        impactOfCavityInsulation: 67,
        impactOfSolidWallInsulation: 69
      },
      recommendedImprovements: valid_recommendations
    }.freeze
  end

  def assessment_without(key)
    assessment = valid_assessment_body.dup
    assessment.delete(key)
    assessment
  end

  def migrate_invalid_recommendations(recommendations)
    assessment = valid_assessment_body.dup

    if recommendations
      assessment[:recommendedImprovements] = recommendations
    else
      assessment.delete(:recommendedImprovements)
    end

    scheme_id = add_scheme_and_get_id
    add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

    migrate_assessment('123-456', assessment, [422])
  end

  context 'when migrating an assessment with badly structured improvements' do
    it 'rejects an assessment where the improvements key is missing' do
      migrate_invalid_recommendations(nil)
    end

    it 'rejects an assessment where the improvements is not a list' do
      migrate_invalid_recommendations('Get a new boiler')
    end

    it 'rejects an assessment where each improvement is not an object' do
      migrate_invalid_recommendations([1, 3, 5])
    end

    it 'rejects improvements that dont contain a sequence' do
      recommendations = valid_recommendations
      recommendations[0].delete(:sequence)
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects improvements that dont contain a improvementCode' do
      recommendations = valid_recommendations
      recommendations[0].delete(:improvementCode)
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects improvements that dont contain a indicativeCost' do
      recommendations = valid_recommendations
      recommendations[0].delete(:indicativeCost)
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects improvements that dont contain a typicalSaving' do
      recommendations = valid_recommendations
      recommendations[0].delete(:typicalSaving)
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects sequences that are not integers' do
      recommendations = valid_recommendations
      recommendations[0][:sequence] = 'first'
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects sequences that dont have a zero sequence' do
      recommendations = valid_recommendations
      recommendations[0][:sequence] = 2
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects non-continuous sequences' do
      recommendations = valid_recommendations
      recommendations[0][:sequence] = 0
      recommendations[1][:sequence] = 5
      migrate_invalid_recommendations(recommendations)
    end

    it 'rejects sequences that contain negative numbers' do
      recommendations = valid_recommendations
      recommendations[0][:sequence] = -1
      recommendations[1][:sequence] = 0
      migrate_invalid_recommendations(recommendations)
    end
  end

  it 'rejects typicalSavings that are not decimals' do
    recommendations = valid_recommendations
    recommendations[0][:typicalSaving] = 'first'
    migrate_invalid_recommendations(recommendations)
  end

  context 'when migrating an assessment with correctly structured improvements' do
    it 'returns a 200 when all possible recommendation data items present' do
      assessment = valid_assessment_body.dup
      assessment[:recommendedImprovements] = valid_recommendations
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      migrate_assessment('123-456', assessment, [200])
    end

    it 'returns 200 when the optional data items are empty' do
      recommendations = valid_recommendations
      recommendations[0][:indicativeCost] = ''
      recommendations[1][:improvementCategory] = ''
      assessment = valid_assessment_body.dup
      assessment[:recommendedImprovements] = valid_recommendations
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      migrate_assessment('123-456', assessment, [200])
    end
  end
end
