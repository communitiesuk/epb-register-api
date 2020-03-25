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
      },
      recommendedImprovements: [{ sequence: 0 }]
    }.freeze
  end

  def assessment_without(key)
    assessment = valid_assessment_body.dup
    assessment.delete(key)
    assessment
  end

  context 'when migrating an assessment with badly structured improvements' do
    it 'rejects an assessment where the improvements key is missing' do
      assessment_without_improvements_key =
        assessment_without(:recommendedImprovements)
      scheme_id = authenticate_and { add_scheme }
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      response =
        migrate_assessment('456-982', assessment_without_improvements_key)
      expect(response.status).to eq(422)
    end

    it 'rejects an assessment where the improvements is not a list' do
      bad_assessment = valid_assessment_body.dup
      bad_assessment[:recommendedImprovements] = 'Get a new boiler'
      scheme_id = authenticate_and { add_scheme }
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      response = migrate_assessment('456-982', bad_assessment)
      expect(response.status).to eq(422)
    end

    it 'rejects an assessment where each improvement is not an object' do
      bad_assessment = valid_assessment_body.dup
      bad_assessment[:recommendedImprovements] = [1, 3, 5]
      scheme_id = authenticate_and { add_scheme }
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      response = migrate_assessment('456-982', bad_assessment)
      expect(response.status).to eq(422)
    end

    it 'rejects improvements that dont contain a sequence' do
      bad_assessment = valid_assessment_body.dup
      bad_assessment[:recommendedImprovements][0].delete(:sequence)
      scheme_id = authenticate_and { add_scheme }
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      pp bad_assessment
      response = migrate_assessment('456-982', bad_assessment)
      expect(response.status).to eq(422)
    end
  end
end
