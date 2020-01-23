describe 'Acceptance::Postcodes' do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_with_contact_request_body) do
    {
      firstName: 'Some',
      middleNames: 'Middle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      },
      searchResultsComparisonPostcode: 'SE1 7EZ'
    }
  end

  def add_postcodes(postcode, latitude = 0, longitude = 0, clean = true)
    db = ActiveRecord::Base

    truncate(postcode) if clean

    db.connection.execute(
      "INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES('#{
        db.sanitize_sql(postcode)
      }', #{latitude.to_f}, #{longitude.to_f})"
    )
  end

  def add_outcodes(outcode, latitude = 0, longitude = 0, clean = true)
    db = ActiveRecord::Base

    truncate(outcode) if clean

    db.connection.execute(
      "INSERT INTO postcode_outcode_geolocations (outcode, latitude, longitude) VALUES('#{
        db.sanitize_sql(outcode)
      }', #{latitude.to_f}, #{longitude.to_f})"
    )
  end

  def truncate(postcode)
    if postcode ==
         Regexp.new('^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$', Regexp::IGNORECASE)
      ActiveRecord::Base.connection.execute(
        'TRUNCATE TABLE postcode_geolocation'
      )
    else
      ActiveRecord::Base.connection.execute(
        'TRUNCATE TABLE postcode_outcode_geolocations'
      )
    end
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

    it 'has the over all hash of the shape we expect' do
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

      expected_response =
        JSON.parse(
          {
            assessor: {
              firstName: 'Some',
              lastName: 'Person',
              middleNames: 'Middle',
              registeredBy: { name: 'Happy EPC', schemeId: 25 },
              schemeAssessorId: 'ASSESSOR999',
              searchResultsComparisonPostcode: 'SE1 7EZ',
              dateOfBirth: '1991-02-25',
              contactDetails: {
                telephoneNumber: '010199991010101', email: 'person@person.com'
              }
            },
            distance: 0.0
          }.to_json
        )

      response_json['results'][0]['assessor']['registeredBy']['schemeId'] = 25

      expect(response_json['results'][0]).to eq(expected_response)
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

    it 'shows distance of assessors inside of 1 degree latitude/longitude' do
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

    context 'when the postcode is not found' do
      it 'returns results based on the outcode of the postcode' do
        add_postcodes('SE1 5BN', 51.5045, 0.0865)

        add_outcodes('SE1', 51.5045, 0.4865)

        scheme_id = authenticate_and { add_scheme('Happy EPC') }

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = 'SE1 5BN'

        authenticate_and do
          add_assessor(
            scheme_id,
            'ASSESSOR999',
            valid_assessor_with_contact_request_body
          )
        end
        response = authenticate_and { assessors_search_by_postcode('SE19SY') }

        response_json = JSON.parse(response.body)
        expect(response_json['results'][0]).to include('distance')
      end

      it 'returns error when neither postcode or outcode are found' do
        add_postcodes('SE1 5BN', 51.5045, 0.0865)

        add_outcodes('SE1', 51.5045, 0.4865)

        scheme_id = authenticate_and { add_scheme('Happy EPC') }

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = 'SE1 5BN'

        authenticate_and do
          add_assessor(
            scheme_id,
            'ASSESSOR999',
            valid_assessor_with_contact_request_body
          )
        end
        response = authenticate_and { assessors_search_by_postcode('NE19SY') }

        response_json = JSON.parse(response.body)
        p response_json
        expect((response_json).key?('errors')).to eq(true)
      end
    end
  end
end
