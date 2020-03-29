describe 'Searching for assessments' do
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
      recommendedImprovements: [
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
        }
      ]
    }.freeze
  end

  def assessments_search_by_postcode(postcode)
    get "/api/assessments/domestic-epc/search?postcode=#{postcode}"
  end
  def assessments_search_by_assessment_id(assessment_id)
    get "/api/assessments/domestic-epc/search?assessment_id=#{assessment_id}"
  end
  def assessments_search_by_street_name_and_town(street_name, town)
    get "/api/assessments/domestic-epc/search?street_name=#{street_name}&town=#{
          town
        }"
  end

  def add_assessment(assessment_id, body)
    put("/api/assessments/domestic-epc/#{assessment_id}", body.to_json)
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

      expect(response_json['data']['assessments']).to be_an(Array)
    end

    it 'can handle a lowercase postcode' do
      response = authenticate_and { assessments_search_by_postcode('e20sz') }

      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessments']).to be_an(Array)
    end

    it 'has the properties we expect' do
      response = authenticate_and { assessments_search_by_postcode('SE17EZ') }

      response_json = JSON.parse(response.body)

      expect(response_json).to include('data', 'meta')
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
            addressLine4: '',
            heatDemand: {
              currentSpaceHeatingDemand: 222,
              currentWaterHeatingDemand: 321,
              impactOfLoftInsulation: 79,
              impactOfCavityInsulation: 67,
              impactOfSolidWallInsulation: 69
            }
          }.to_json
        )

      expect(response_json['data']['assessments'][0]).to eq(expected_response)
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

      expect(response_json['data']['assessments']).to be_an(Array)
    end

    it 'has the properties we expect' do
      response =
        authenticate_and { assessments_search_by_assessment_id('123-987') }

      response_json = JSON.parse(response.body)

      expect(response_json).to include('data', 'meta')
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
            addressLine4: '',
            heatDemand: {
              currentSpaceHeatingDemand: 222,
              currentWaterHeatingDemand: 321,
              impactOfLoftInsulation: 79,
              impactOfCavityInsulation: 67,
              impactOfSolidWallInsulation: 69
            }
          }.to_json
        )

      expect(response_json['data']['assessments'][0]).to eq(expected_response)
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

        expect(response_json['data']['assessments']).to be_an(Array)
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

        expect(response_json).to include('data', 'meta')
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
              addressLine4: '',
              heatDemand: {
                currentSpaceHeatingDemand: 222,
                currentWaterHeatingDemand: 321,
                impactOfLoftInsulation: 79,
                impactOfCavityInsulation: 67,
                impactOfSolidWallInsulation: 69
              }
            }.to_json
          )

        expect(response_json['data']['assessments'][0]).to eq(expected_response)
      end
    end
  end
end
