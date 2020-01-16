describe 'Acceptance::Postcodes' do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_with_contact_request_body) do
    {
      firstName: 'Some',
      middleNames: 'middle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      },
      searchResultsComparisonPostcode: 'SE1 7EZ'
    }
  end

  def add_postcodes(postcode, latitude = 0, longitude = 0, clean = true)
    postcodes_gateway = Gateway::PostcodesGateway.new

    postcodes_gateway.truncate if clean
    postcodes_gateway.add(postcode, latitude, longitude)
  end

  def assessors_search_by_postcode(postcode)
    get "/api/assessors/search/#{postcode}"
  end

  def add_assessor(scheme_id, assessor_id, body)
    put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
  end

  def add_scheme(name = 'test scheme')
    JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
  end

  context 'when a search postcode is invalid' do
    it 'returns status 409 for a get' do
      expect(
        authenticate_and { assessors_search_by_postcode('73334') }.status
      ).to eq(409)
    end
  end

  context 'when a search postcode is valid' do
    it 'returns status 200 for a get' do
      add_postcodes('SE1 7EZ')
      expect(
        authenticate_and { assessors_search_by_postcode('SE17EZ') }.status
      ).to eq(200)
    end

    it 'looks as it should' do
      add_postcodes('SE1 7EZ')

      response = authenticate_and { assessors_search_by_postcode('SE17EZ') }

      response_json = JSON.parse(response.body)

      expect(response_json['results']).to be_an(Array)
    end

    it 'can handle a lowercase postcode' do
      add_postcodes('E2 0SZ')

      response = authenticate_and { assessors_search_by_postcode('e20sz') }

      response_json = JSON.parse(response.body)

      expect(response_json['results']).to be_an(Array)
    end

    it 'has the properties we expect' do
      add_postcodes('SE1 7EZ')

      response = authenticate_and { assessors_search_by_postcode('SE17EZ') }

      response_json = JSON.parse(response.body)

      expect(response_json).to include('results', 'searchPostcode')
    end

    it 'has the assessors of the shape we expect' do
      add_postcodes('SE1 7EZ')

      scheme_id = authenticate_and { add_scheme('Happy EPC') }

      authenticate_and do
        add_assessor(
          scheme_id,
          'ASSESSOR999',
          valid_assessor_with_contact_request_body
        )
      end

      response = authenticate_and { assessors_search_by_postcode('SE17EZ') }

      response_json = JSON.parse(response.body)

      expect(response_json['results'][0]).to include('assessor', 'distance')
    end

    it 'does not show assessors outside of 1 degree latitude/longitude' do
      add_postcodes('SE1 9SG', 51.5045, 0.0865)

      add_postcodes('NE8 2BH', 54.9680, 1.6062, false)

      scheme_id = authenticate_and { add_scheme('Happy EPC') }

      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = 'NE8 2BH'

      authenticate_and do
        add_assessor(
          scheme_id,
          'ASSESSOR999',
          valid_assessor_with_contact_request_body
        )
      end

      response = authenticate_and { assessors_search_by_postcode('SE19SG') }

      response_json = JSON.parse(response.body)

      expect(response_json['results'].size).to eq(0)
    end

    it 'does not show assessors outside of 1 degree latitude/longitude' do
      add_postcodes('SE1 9SG', 51.5045, 0.0865)

      add_postcodes('SW8 5BN', 51.4818, 0.1444, false)

      scheme_id = authenticate_and { add_scheme('Happy EPC') }

      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = 'SW8 5BN'

      authenticate_and do
        add_assessor(
          scheme_id,
          'ASSESSOR999',
          valid_assessor_with_contact_request_body
        )
      end

      response = authenticate_and { assessors_search_by_postcode('SE19SG') }

      response_json = JSON.parse(response.body)

      expect(response_json['results'][0]['distance']).to be_between(2, 4)
    end
  end
end
