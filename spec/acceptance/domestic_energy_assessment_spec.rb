# frozen_string_literal: true

describe 'Acceptance::Assessor' do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: 'Someone',
      middleNames: 'Muddle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      searchResultsComparisonPostcode: '',
      qualifications: { domesticRdSap: 'ACTIVE' }
    }
  end

  let(:valid_assessment_body) do
    {
      assessmentId: '123-987',
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
      town: 'Brighton'
    }.freeze
  end

  def assessment_without(key)
    assessment = valid_assessment_body.dup
    assessment.delete(key)
    assessment
  end

  def add_scheme(name = 'test scheme')
    JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
  end

  def add_assessor(scheme_id, assessor_id, body)
    put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
  end

  def fetch_assessment(assessment_id)
    get "api/assessments/domestic-energy-performance/#{assessment_id}"
  end

  def migrate_assessment(assessment_id, assessment_body)
    put(
      "api/assessments/domestic-energy-performance/#{assessment_id}",
      assessment_body.to_json
    )
  end

  context 'when a domestic assessment doesnt exist' do
    it 'returns status 404 for a get' do
      expect(
        authenticate_and { fetch_assessment('DOESNT-EXIST') }.status
      ).to eq(404)
    end

    it 'returns an error message structure' do
      response_body = authenticate_and { fetch_assessment('DOESNT-EXIST') }.body
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
      scheme_id = authenticate_and { add_scheme }
      authenticate_and do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      end

      authenticate_and do
        migrate_assessment('15650-651625-18267167', valid_assessment_body)
      end
      response = authenticate_and { fetch_assessment('15650-651625-18267167') }
      expect(response.status).to eq(200)
    end

    it 'returns the assessment details' do
      scheme_id = authenticate_and { add_scheme }
      authenticate_and do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      end

      authenticate_and do
        migrate_assessment('15650-651625-18267167', valid_assessment_body)
      end
      response =
        JSON.parse(
          authenticate_and { fetch_assessment('15650-651625-18267167') }.body
        )
      expected_response =
        JSON.parse(
          {
            schemeAssessorId: valid_assessment_body[:schemeAssessorId],
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
            currentEnergyEfficiencyBand: 'c',
            potentialEnergyEfficiencyBand: 'c',
            postcode: valid_assessment_body[:postcode],
            dateOfExpiry: valid_assessment_body[:dateOfExpiry],
            town: valid_assessment_body[:town],
            addressLine1: valid_assessment_body[:addressLine1],
            addressLine2: valid_assessment_body[:addressLine2],
            addressLine3: valid_assessment_body[:addressLine4],
            addressLine4: valid_assessment_body[:addressLine4]
          }.to_json
        )
      expect(response).to eq(expected_response)
    end
  end

  context 'when migrating a domestic assessment (put)' do
    it 'returns a 200 for a valid assessment' do
      scheme_id = authenticate_and { add_scheme }
      authenticate_and do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      end

      response =
        authenticate_and do
          migrate_assessment('123-456', valid_assessment_body)
        end
      expect(response.status).to eq(200)
    end

    it 'returns the assessment that was migrated' do
      scheme_id = authenticate_and { add_scheme }
      authenticate_and do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      end

      response =
        authenticate_and do
          migrate_assessment('123-456', valid_assessment_body).body
        end

      migrated_assessment = JSON.parse(response)
      expected_response =
        JSON.parse(
          {
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
            postcode: valid_assessment_body[:postcode],
            dateOfExpiry: valid_assessment_body[:dateOfExpiry],
            town: valid_assessment_body[:town],
            addressLine1: valid_assessment_body[:addressLine1],
            addressLine2: valid_assessment_body[:addressLine2],
            addressLine3: valid_assessment_body[:addressLine4],
            addressLine4: valid_assessment_body[:addressLine4],
            schemeAssessorId: valid_assessment_body[:schemeAssessorId]
          }.to_json
        )

      expect(migrated_assessment).to eq(expected_response)
    end

    it 'rejects a assessment without an address summary' do
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_without(:addressSummary))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with an address summary that is not a string' do
      assessment_with_dodgy_address = valid_assessment_body.dup
      assessment_with_dodgy_address[:addressSummary] = 123_321
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_address)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment without a date of assessment' do
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_without(:dateOfAssessment))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with an date of assessment that is not a date' do
      assessment_with_dodge_date_of_address = valid_assessment_body.dup
      assessment_with_dodge_date_of_address[:dateOfAssessment] = 'horse'
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodge_date_of_address)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment without a date of assessment' do
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_without(:dateRegistered))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with a date of assessment that is not a date' do
      assessment_with_dodge_date_of_assessment = valid_assessment_body.dup
      assessment_with_dodge_date_of_assessment[:dateRegistered] = 'horse'
      response =
        authenticate_and do
          migrate_assessment(
            '123-456',
            assessment_with_dodge_date_of_assessment
          )
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment without a total floor area' do
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_without(:totalFloorArea))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with a total floor area that is not an integer' do
      assessment_with_dodgy_total_floor_area = valid_assessment_body.dup
      assessment_with_dodgy_total_floor_area[:totalFloorArea] = 'horse'
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_total_floor_area)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment without a dwelling type' do
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_without(:dwellingType))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with a dwelling type that is not a string' do
      assessment_with_dodgy_dwelling_type = valid_assessment_body.dup
      assessment_with_dodgy_dwelling_type[:dwellingType] = 456_765
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_dwelling_type)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment without a type of assessment' do
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_without(:typeOfAssessment))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with a type of assessment that is not a string' do
      assessment_with_dodgy_type_of_assessment = valid_assessment_body.dup
      assessment_with_dodgy_type_of_assessment[:typeOfAssessment] = 'bird'
      response =
        authenticate_and do
          migrate_assessment(
            '123-456',
            assessment_with_dodgy_type_of_assessment
          )
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with a type of current energy efficiency rating that is not an integer' do
      assessment_with_dodgy_current_rating = valid_assessment_body.dup
      assessment_with_dodgy_current_rating[:currentEnergyEfficiencyRating] =
        'one'
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_current_rating)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a assessment with a type of potential energy efficiency rating that is not an integer' do
      assessment_with_dodgy_potential_rating = valid_assessment_body.dup
      assessment_with_dodgy_potential_rating[:potentialEnergyEfficiencyRating] =
        'two'
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_potential_rating)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects an assessment with a invalid current energy efficiency rating' do
      assessment_with_dodgy_current_rating = valid_assessment_body.dup
      assessment_with_dodgy_current_rating[:currentEnergyEfficiencyRating] = 175
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_current_rating)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects an assessment with a invalid potential energy efficiency rating' do
      assessment_with_dodgy_potential_rating = valid_assessment_body.dup
      assessment_with_dodgy_potential_rating[:currentEnergyEfficiencyRating] =
        175
      response =
        authenticate_and do
          migrate_assessment('123-456', assessment_with_dodgy_potential_rating)
        end
      expect(response.status).to eq(422)
    end
  end

  context 'when searching for an assessment' do
    def assessments_search_by_postcode(postcode)
      get "/api/assessments/domestic-energy-performance/search?postcode=#{
            postcode
          }"
    end
    def assessments_search_by_assessment_id(assessment_id)
      get "/api/assessments/domestic-energy-performance/search?assessment_id=#{
            assessment_id
          }"
    end
    def assessments_search_by_street_name_and_town(street_name, town)
      get "/api/assessments/domestic-energy-performance/search?street_name=#{
            street_name
          }&town=#{town}"
    end

    def add_assessment(assessment_id, body)
      put(
        "/api/assessments/domestic-energy-performance/#{assessment_id}",
        body.to_json
      )
    end

    context 'when a search postcode is valid' do
      it 'returns status 200 for a get' do
        expect(
          authenticate_and { assessments_search_by_postcode('SE17EZ') }.status
        ).to eq(200)
      end

      it 'looks as it should' do
        response = authenticate_and { assessments_search_by_postcode('SE17EZ') }

        response_json = JSON.parse(response.body)

        expect(response_json['results']).to be_an(Array)
      end

      it 'can handle a lowercase postcode' do
        response = authenticate_and { assessments_search_by_postcode('e20sz') }

        response_json = JSON.parse(response.body)

        expect(response_json['results']).to be_an(Array)
      end

      it 'has the properties we expect' do
        response = authenticate_and { assessments_search_by_postcode('SE17EZ') }

        response_json = JSON.parse(response.body)

        expect(response_json).to include('results', 'searchQuery')
      end

      it 'has the over all hash of the shape we expect' do
        scheme_id = authenticate_and { add_scheme }
        authenticate_and do
          add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
        end

        authenticate_and { add_assessment('123-987', valid_assessment_body) }

        response = authenticate_and { assessments_search_by_postcode('SE17EZ') }

        response_json = JSON.parse(response.body)

        puts response.body

        expected_response =
          JSON.parse(
            {
              schemeAssessorId: 'TEST123456',
              assessmentId: '123-987',
              dateOfAssessment: '2020-01-13',
              dateRegistered: '2020-01-13',
              totalFloorArea: 1_000,
              typeOfAssessment: 'RdSAP',
              dwellingType: 'Top floor flat',
              addressSummary: '123 Victoria Street, London, SW1A 1BD',
              currentEnergyEfficiencyRating: 75,
              potentialEnergyEfficiencyRating: 80,
              currentEnergyEfficiencyBand: 'c',
              potentialEnergyEfficiencyBand: 'c',
              postcode: 'SE1 7EZ',
              dateOfExpiry: '2021-01-01',
              town: 'Brighton',
              addressLine1: 'Flat 33',
              addressLine2: '18 Palmtree Road',
              addressLine3: '',
              addressLine4: ''
            }.to_json
          )

        expect(response_json['results'][0]).to eq(expected_response)
      end
    end

    context 'when a search assessment id is valid' do
      it 'returns status 200 for a get' do
        expect(
          authenticate_and {
            assessments_search_by_assessment_id('123-987')
          }.status
        ).to eq(200)
      end

      it 'looks as it should' do
        response =
          authenticate_and { assessments_search_by_assessment_id('123-987') }

        response_json = JSON.parse(response.body)

        expect(response_json['results']).to be_an(Array)
      end

      it 'has the properties we expect' do
        response =
          authenticate_and { assessments_search_by_assessment_id('123-987') }

        response_json = JSON.parse(response.body)

        expect(response_json).to include('results', 'searchQuery')
      end

      it 'has the over all hash of the shape we expect' do
        scheme_id = authenticate_and { add_scheme }
        authenticate_and do
          add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
        end

        authenticate_and { add_assessment('123-987', valid_assessment_body) }

        response =
          authenticate_and { assessments_search_by_assessment_id('123-987') }

        response_json = JSON.parse(response.body)

        expected_response =
          JSON.parse(
            {
              schemeAssessorId: 'TEST123456',
              assessmentId: '123-987',
              dateOfAssessment: '2020-01-13',
              dateRegistered: '2020-01-13',
              totalFloorArea: 1_000,
              typeOfAssessment: 'RdSAP',
              dwellingType: 'Top floor flat',
              addressSummary: '123 Victoria Street, London, SW1A 1BD',
              currentEnergyEfficiencyRating: 75,
              potentialEnergyEfficiencyRating: 80,
              currentEnergyEfficiencyBand: 'c',
              potentialEnergyEfficiencyBand: 'c',
              postcode: 'SE1 7EZ',
              dateOfExpiry: '2021-01-01',
              town: 'Brighton',
              addressLine1: 'Flat 33',
              addressLine2: '18 Palmtree Road',
              addressLine3: '',
              addressLine4: ''
            }.to_json
          )

        expect(response_json['results'][0]).to eq(expected_response)
      end
    end

    context 'when using town and street name' do
      context 'and town is missing but street name is present' do
        it 'returns status 400 for a get' do
          expect(
            authenticate_and {
              assessments_search_by_street_name_and_town('Palmtree Road', '')
            }.status
          ).to eq(400)
        end

        it 'contains the correct error message' do
          response_body =
            authenticate_and do
              assessments_search_by_street_name_and_town('Palmtree Road', '')
            end.body
          expect(JSON.parse(response_body)).to eq(
            {
              'errors' => [
                {
                  'code' => 'MALFORMED_REQUEST',
                  'title' => 'Required query params missing'
                }
              ]
            }
          )
        end
      end

      context 'and street name is missing but town is present' do
        it 'returns status 400 for a get' do
          expect(
            authenticate_and {
              assessments_search_by_street_name_and_town('', 'Brighton')
            }.status
          ).to eq(400)
        end

        it 'contains the correct error message' do
          response_body =
            authenticate_and do
              assessments_search_by_street_name_and_town('', 'Brighton')
            end.body
          expect(JSON.parse(response_body)).to eq(
            {
              'errors' => [
                {
                  'code' => 'MALFORMED_REQUEST',
                  'title' => 'Required query params missing'
                }
              ]
            }
          )
        end
      end

      context 'and required parameters are present' do
        it 'returns status 200 for a get' do
          expect(
            authenticate_and {
              assessments_search_by_street_name_and_town(
                'Palmtree Road',
                'Brighton'
              )
            }.status
          ).to eq(200)
        end

        it 'looks as it should' do
          response =
            authenticate_and do
              assessments_search_by_street_name_and_town(
                'Palmtree Road',
                'Brighton'
              )
            end

          response_json = JSON.parse(response.body)

          expect(response_json['results']).to be_an(Array)
        end

        it 'has the properties we expect' do
          response =
            authenticate_and do
              assessments_search_by_street_name_and_town(
                'Palmtree Road',
                'Brighton'
              )
            end

          response_json = JSON.parse(response.body)

          expect(response_json).to include('results', 'searchQuery')
        end

        it 'has the over all hash of the shape we expect' do
          scheme_id = authenticate_and { add_scheme }
          authenticate_and do
            add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
          end

          authenticate_and { add_assessment('123-987', valid_assessment_body) }

          response =
            authenticate_and do
              assessments_search_by_street_name_and_town(
                'Palmtree Road',
                'Brighton'
              )
            end

          response_json = JSON.parse(response.body)

          expected_response =
            JSON.parse(
              {
                schemeAssessorId: 'TEST123456',
                assessmentId: '123-987',
                dateOfAssessment: '2020-01-13',
                dateRegistered: '2020-01-13',
                totalFloorArea: 1_000,
                typeOfAssessment: 'RdSAP',
                dwellingType: 'Top floor flat',
                addressSummary: '123 Victoria Street, London, SW1A 1BD',
                currentEnergyEfficiencyRating: 75,
                potentialEnergyEfficiencyRating: 80,
                currentEnergyEfficiencyBand: 'c',
                potentialEnergyEfficiencyBand: 'c',
                postcode: 'SE1 7EZ',
                dateOfExpiry: '2021-01-01',
                town: 'Brighton',
                addressLine1: 'Flat 33',
                addressLine2: '18 Palmtree Road',
                addressLine3: '',
                addressLine4: ''
              }.to_json
            )

          expect(response_json['results'][0]).to eq(expected_response)
        end
      end
    end
  end
end
