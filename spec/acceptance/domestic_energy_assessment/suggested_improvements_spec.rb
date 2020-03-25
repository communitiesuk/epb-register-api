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
      }
    }.freeze
  end

  def assessment_without(key)
    assessment = valid_assessment_body.dup
    assessment.delete(key)
    assessment
  end

  def add_scheme(name = 'test scheme')
    authenticate_and do
      JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
    end
  end

  def add_assessor(scheme_id, assessor_id, body)
    authenticate_and do
      put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
    end
  end

  def fetch_assessment(assessment_id)
    authenticate_and { get "api/assessments/domestic-epc/#{assessment_id}" }
  end

  def migrate_assessment(assessment_id, assessment_body)
    authenticate_and do
      put(
        "api/assessments/domestic-epc/#{assessment_id}",
        assessment_body.to_json
      )
    end
  end

  context 'when migrating the suggested improvements' do
    it 'rejects an assessment where the improvements key is missing' do
      assessment_without_improvements_key = valid_assessment_body.dup
      assessment_without_improvements_key.delete(:recommendedImprovements)
      scheme_id = authenticate_and { add_scheme }
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      response =
        migrate_assessment('456-982', assessment_without_improvements_key)
      expect(response.status).to eq(422)
    end
  end
end
