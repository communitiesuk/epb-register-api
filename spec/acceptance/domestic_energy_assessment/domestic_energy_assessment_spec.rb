# frozen_string_literal: true

describe 'Acceptance::DomesticEnergyAssessment' do
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
      totalFloorArea: 1_000.45,
      typeOfAssessment: 'RdSAP',
      dwellingType: 'Top floor flat',
      addressSummary: '123 Victoria Street, London, SW1A 1BD',
      currentEnergyEfficiencyRating: 75,
      potentialEnergyEfficiencyRating: 80,
      currentCarbonEmission: 2.4,
      potentialCarbonEmission: 1.4,
      optOut: false,
      postcode: 'SE1 7EZ',
      dateOfExpiry: '2021-01-01',
      addressLine1: 'Flat 33',
      addressLine2: '18 Palmtree Road',
      addressLine3: '',
      addressLine4: '',
      town: 'Brighton',
      heatDemand: {
        currentSpaceHeatingDemand: 222.23,
        currentWaterHeatingDemand: 321.14,
        impactOfLoftInsulation: 79,
        impactOfCavityInsulation: 67,
        impactOfSolidWallInsulation: 69
      },
      recommendedImprovements: [
        {
          sequence: 0,
          improvementCode: '1',
          indicativeCost: '£200 - £4,000',
          typicalSaving: 400.21,
          improvementCategory: 'string',
          improvementType: 'string',
          energyPerformanceRatingImprovement: 80,
          environmentalImpactRatingImprovement: 90,
          greenDealCategoryCode: 'string'
        }
      ]
    }.freeze
  end

  def assessment_without(key)
    assessment = valid_assessment_body.dup
    assessment.delete(key)
    assessment
  end

  context 'security' do
    it 'rejects a request that is not authenticated' do
      fetch_assessment('123', [401], false)
    end

    it 'rejects a request with the wrong scopes' do
      fetch_assessment('124', [403], true, {}, %w[wrong:scope])
    end
  end

  context 'when a domestic assessment doesnt exist' do
    it 'returns status 404 for a get' do
      fetch_assessment('DOESNT-EXIST', [404])
    end

    it 'returns an error message structure' do
      response_body = fetch_assessment('DOESNT-EXIST', [404]).body
      expect(JSON.parse(response_body)).to eq(
        {
          'errors' => [
            { 'code' => 'NOT_FOUND', 'title' => 'Assessment not found' }
          ]
        }
      )
    end
  end

  context 'when a domestic assessment exists' do
    it 'returns a 200' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      migrate_assessment('15650-651625-18267167', valid_assessment_body, [200])

      response = fetch_assessment('15650-651625-18267167')
      expect(response.status).to eq(200)
    end

    it 'returns the assessment details' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      migrate_assessment('15650-651625-18267167', valid_assessment_body)

      response = JSON.parse(fetch_assessment('15650-651625-18267167').body)

      expected_response =
        JSON.parse(
          {
            assessor: {
              schemeAssessorId: valid_assessment_body[:schemeAssessorId],
              registeredBy: { schemeId: scheme_id, name: 'test scheme' },
              firstName: valid_assessor_request_body[:firstName],
              middleNames: valid_assessor_request_body[:middleNames],
              lastName: valid_assessor_request_body[:lastName],
              dateOfBirth: valid_assessor_request_body[:dateOfBirth],
              contactDetails: {
                telephoneNumber:
                  valid_assessor_request_body[:contactDetails][
                    :telephoneNumber
                  ],
                email: valid_assessor_request_body[:contactDetails][:email]
              },
              searchResultsComparisonPostcode: '',
              qualifications: {
                domesticSap: 'INACTIVE',
                domesticRdSap: 'ACTIVE',
                nonDomesticSp3: 'INACTIVE',
                nonDomesticCc4: 'INACTIVE',
                nonDomesticDec: 'INACTIVE',
                nonDomesticNos3: 'INACTIVE',
                nonDomesticNos4: 'INACTIVE',
                nonDomesticNos5: 'INACTIVE'
              }
            },
            dateOfAssessment: valid_assessment_body[:dateOfAssessment],
            dateRegistered: valid_assessment_body[:dateRegistered],
            totalFloorArea: valid_assessment_body[:totalFloorArea],
            typeOfAssessment: valid_assessment_body[:typeOfAssessment],
            dwellingType: valid_assessment_body[:dwellingType],
            addressSummary: valid_assessment_body[:addressSummary],
            assessmentId: '15650-651625-18267167',
            currentEnergyEfficiencyRating:
              valid_assessment_body[:currentEnergyEfficiencyRating],
            potentialEnergyEfficiencyRating:
              valid_assessment_body[:potentialEnergyEfficiencyRating],
            currentCarbonEmission:
              valid_assessment_body[:currentCarbonEmission],
            potentialCarbonEmission:
              valid_assessment_body[:potentialCarbonEmission],
            currentEnergyEfficiencyBand: 'c',
            potentialEnergyEfficiencyBand: 'c',
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
                valid_assessment_body[:heatDemand][:impactOfSolidWallInsulation]
            },
            recommendedImprovements: [
              {
                sequence: 0,
                improvementCode: '1',
                indicativeCost: '£200 - £4,000',
                typicalSaving: '400.21',
                improvementCategory: 'string',
                improvementType: 'string',
                energyPerformanceRatingImprovement: 80,
                environmentalImpactRatingImprovement: 90,
                greenDealCategoryCode: 'string'
              }
            ]
          }.to_json
        )
      expect(response['data']).to eq(expected_response)
    end
  end

  context 'when migrating a domestic assessment (put)' do
    context 'security' do
      it 'rejects a request that is not authenticated' do
        migrate_assessment('123', valid_assessment_body, [401], false)
      end
      it 'rejects a request with the wrong scopes' do
        migrate_assessment(
          '123',
          valid_assessment_body,
          [403],
          true,
          {},
          %w[wrong:scope]
        )
      end
    end

    it 'returns a 200 for a valid assessment' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      migrate_assessment('123-456', valid_assessment_body, [200])
    end

    it 'allows migration of an assessment with limited address info' do
      scheme_id = add_scheme_and_get_id

      assessment_request_body_with_limited_address = valid_assessment_body.dup
      assessment_request_body_with_limited_address[:addressLine2] = nil
      assessment_request_body_with_limited_address[:addressLine3] = nil
      assessment_request_body_with_limited_address[:addressLine4] = nil

      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      migrate_assessment(
        '123-456',
        assessment_request_body_with_limited_address,
        [200]
      )
    end

    it 'returns the assessment that was migrated' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      response = migrate_assessment('123-456', valid_assessment_body).body

      migrated_assessment = JSON.parse(response, symbolize_names: true)
      expected_response = {
        dateOfAssessment: valid_assessment_body[:dateOfAssessment],
        dateRegistered: valid_assessment_body[:dateRegistered],
        totalFloorArea: valid_assessment_body[:totalFloorArea],
        typeOfAssessment: valid_assessment_body[:typeOfAssessment],
        dwellingType: valid_assessment_body[:dwellingType],
        addressSummary: valid_assessment_body[:addressSummary],
        assessmentId: '123-456',
        currentEnergyEfficiencyRating:
          valid_assessment_body[:currentEnergyEfficiencyRating],
        potentialEnergyEfficiencyRating:
          valid_assessment_body[:potentialEnergyEfficiencyRating],
        currentCarbonEmission: valid_assessment_body[:currentCarbonEmission],
        potentialCarbonEmission:
          valid_assessment_body[:potentialCarbonEmission],
        postcode: valid_assessment_body[:postcode],
        dateOfExpiry: valid_assessment_body[:dateOfExpiry],
        town: valid_assessment_body[:town],
        addressLine1: valid_assessment_body[:addressLine1],
        addressLine2: valid_assessment_body[:addressLine2],
        addressLine3: valid_assessment_body[:addressLine4],
        addressLine4: valid_assessment_body[:addressLine4],
        schemeAssessorId: valid_assessment_body[:schemeAssessorId],
        potentialEnergyEfficiencyBand: 'c',
        currentEnergyEfficiencyBand: 'c',
        optOut: false,
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
            valid_assessment_body[:heatDemand][:impactOfSolidWallInsulation]
        },
        recommendedImprovements: [
          {
            sequence: 0,
            improvementCode: '1',
            indicativeCost: '£200 - £4,000',
            typicalSaving: 400.21,
            improvementCategory: 'string',
            improvementType: 'string',
            energyPerformanceRatingImprovement: 80,
            environmentalImpactRatingImprovement: 90,
            greenDealCategoryCode: 'string'
          }
        ]
      }

      expect(migrated_assessment[:data]).to eq(expected_response)
    end

    it 'rejects a assessment without an address summary' do
      migrate_assessment('123-456', assessment_without(:addressSummary), [422])
    end

    it 'rejects a assessment with an address summary that is not a string' do
      assessment_with_dodgy_address = valid_assessment_body.dup
      assessment_with_dodgy_address[:addressSummary] = 123_321
      migrate_assessment('123-456', assessment_with_dodgy_address, [422])
    end

    it 'rejects a assessment without a date of assessment' do
      migrate_assessment(
        '123-456',
        assessment_without(:dateOfAssessment),
        [422]
      )
    end

    it 'rejects a assessment with an date of assessment that is not a date' do
      assessment_with_dodge_date_of_address = valid_assessment_body.dup
      assessment_with_dodge_date_of_address[:dateOfAssessment] = 'horse'
      migrate_assessment(
        '123-456',
        assessment_with_dodge_date_of_address,
        [422]
      )
    end

    it 'rejects a assessment without a date of assessment' do
      migrate_assessment('123-456', assessment_without(:dateRegistered), [422])
    end

    it 'rejects a assessment with a date of assessment that is not a date' do
      assessment_with_dodge_date_of_assessment = valid_assessment_body.dup
      assessment_with_dodge_date_of_assessment[:dateRegistered] = 'horse'
      migrate_assessment(
        '123-456',
        assessment_with_dodge_date_of_assessment,
        [422]
      )
    end

    it 'rejects a assessment without a total floor area' do
      migrate_assessment('123-456', assessment_without(:totalFloorArea), [422])
    end

    it 'rejects a assessment with a total floor area that is not an integer' do
      assessment_with_dodgy_total_floor_area = valid_assessment_body.dup
      assessment_with_dodgy_total_floor_area[:totalFloorArea] = 'horse'
      migrate_assessment(
        '123-456',
        assessment_with_dodgy_total_floor_area,
        [422]
      )
    end

    it 'rejects a assessment without a dwelling type' do
      migrate_assessment('123-456', assessment_without(:dwellingType), [422])
    end

    it 'rejects a assessment with a dwelling type that is not a string' do
      assessment_with_dodgy_dwelling_type = valid_assessment_body.dup
      assessment_with_dodgy_dwelling_type[:dwellingType] = 456_765
      migrate_assessment('123-456', assessment_with_dodgy_dwelling_type, [422])
    end

    it 'rejects a assessment without a type of assessment' do
      migrate_assessment(
        '123-456',
        assessment_without(:typeOfAssessment),
        [422]
      )
    end

    it 'rejects a assessment with a type of assessment that is not a string' do
      assessment_with_dodgy_type_of_assessment = valid_assessment_body.dup
      assessment_with_dodgy_type_of_assessment[:typeOfAssessment] = 'bird'
      migrate_assessment(
        '123-456',
        assessment_with_dodgy_type_of_assessment,
        [422]
      )
    end

    it 'rejects a assessment with a type of current energy efficiency rating that is not an integer' do
      assessment_with_dodgy_current_rating = valid_assessment_body.dup
      assessment_with_dodgy_current_rating[:currentEnergyEfficiencyRating] =
        'one'
      migrate_assessment('123-456', assessment_with_dodgy_current_rating, [422])
    end

    it 'rejects a assessment with a type of potential energy efficiency rating that is not an integer' do
      assessment_with_dodgy_potential_rating = valid_assessment_body.dup
      assessment_with_dodgy_potential_rating[:potentialEnergyEfficiencyRating] =
        'two'
      migrate_assessment(
        '123-456',
        assessment_with_dodgy_potential_rating,
        [422]
      )
    end

    it 'rejects an assessment with a invalid current energy efficiency rating' do
      assessment_with_dodgy_current_rating = valid_assessment_body.dup
      assessment_with_dodgy_current_rating[:currentEnergyEfficiencyRating] = 175
      migrate_assessment('123-456', assessment_with_dodgy_current_rating, [422])
    end

    it 'rejects an assessment with a invalid potential energy efficiency rating' do
      assessment_with_dodgy_potential_rating = valid_assessment_body.dup
      assessment_with_dodgy_potential_rating[:currentEnergyEfficiencyRating] =
        175
      migrate_assessment(
        '123-456',
        assessment_with_dodgy_potential_rating,
        [422]
      )
    end

    it 'rejects an assessment without current space heating demand' do
      assessment_without_space_heating_data = valid_assessment_body.dup
      assessment_without_space_heating_data[:heatDemand] = {
        currentWaterHeatingDemand: 4_354
      }
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      migrate_assessment(
        '456-982',
        assessment_without_space_heating_data,
        [422]
      )
    end

    it 'rejects an assessment without current water heating demand' do
      assessment_without_water_heating_data = valid_assessment_body.dup
      assessment_without_water_heating_data[:heatDemand] = {
        currentSpaceHeatingDemand: 4_354
      }
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      migrate_assessment(
        '456-982',
        assessment_without_water_heating_data,
        [422]
      )
    end

    it 'always enters a recommended improvement typical saving with two decimal places' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      valid_assessment_body_typical_saving_more_than_two_dp =
        valid_assessment_body.dup
      valid_assessment_body_typical_saving_more_than_two_dp[
        :recommendedImprovements
      ][
        0
      ][
        :typicalSaving
      ] =
        374.6464

      migrate_assessment(
        '15650-651625-18267167',
        valid_assessment_body_typical_saving_more_than_two_dp
      )

      response = JSON.parse(fetch_assessment('15650-651625-18267167').body)

      expect(
        response['data']['recommendedImprovements'][0]['typicalSaving']
      ).to eq('374.65')
    end
  end
end
