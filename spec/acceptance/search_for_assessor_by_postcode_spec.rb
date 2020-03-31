describe 'Acceptance::SearchForAssessor' do
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
      searchResultsComparisonPostcode: 'SE1 7EZ',
      qualifications: { domesticRdSap: 'ACTIVE' }
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

  context 'when a search postcode is invalid' do
    it 'returns status 409 for a get' do
      assessors_search('73334', 'domesticRdSap', [409])
    end
  end

  context 'when searching without the right params' do
    it 'returns status 409 for postcode search without qualification' do
      add_postcodes('SE1 7EZ')
      expect(
        authenticate_and { get '/api/assessors?postcode=SE17EZ' }.status
      ).to eq(409)
    end
    it 'returns status 409 for no parameters' do
      add_postcodes('SE1 7EZ')
      expect(authenticate_and { get '/api/assessors' }.status).to eq(409)
    end
  end

  context 'when a search postcode is valid' do
    it 'returns status 200 for a get' do
      add_postcodes('SE1 7EZ')
      assessors_search('SE17EZ', 'domesticRdSap', [200])
    end

    it 'looks as it should' do
      add_postcodes('SE1 7EZ')

      response = assessors_search('SE17EZ', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessors']).to be_an(Array)
    end

    it 'can handle a lowercase postcode' do
      add_postcodes('E2 0SZ')

      response = assessors_search('e20sz', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessors']).to be_an(Array)
    end

    it 'has the properties we expect' do
      add_postcodes('SE1 7EZ')

      response = assessors_search('SE17EZ', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expect(response_json).to include('data', 'meta')
    end

    it 'has the assessors of the shape we expect' do
      add_postcodes('SE1 7EZ')
      scheme_id = add_scheme_and_get_name
      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      response = assessors_search('SE17EZ', 'domesticRdSap')
      response_json = JSON.parse(response.body)

      expect(response_json['data']).to include('assessors')
    end

    it 'has the over all hash of the shape we expect' do
      add_postcodes('SE1 7EZ')

      scheme_id = add_scheme_and_get_name

      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      response = assessors_search('SE17EZ', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expected_response =
        JSON.parse(
          {
            firstName: 'Some',
            lastName: 'Person',
            middleNames: 'Middle',
            registeredBy: { name: 'test scheme', schemeId: 25 },
            schemeAssessorId: 'ASSESSOR999',
            searchResultsComparisonPostcode: 'SE1 7EZ',
            dateOfBirth: '1991-02-25',
            contactDetails: {
              telephoneNumber: '010199991010101', email: 'person@person.com'
            },
            qualifications: {
              domesticRdSap: 'ACTIVE',
              nonDomesticSp3: 'INACTIVE',
              nonDomesticCc4: 'INACTIVE'
            },
            distanceFromPostcodeInMiles: 0.0
          }.to_json
        )

      response_json['data']['assessors'][0]['registeredBy']['schemeId'] = 25

      expect(response_json['data']['assessors'][0]).to eq(expected_response)
    end

    it 'does not show assessors outside of 1 degree latitude/longitude' do
      add_postcodes('SE1 9SG', 51.5045, 0.0865)
      add_postcodes('NE8 2BH', 54.9680, 1.6062, false)
      scheme_id = add_scheme_and_get_name
      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = 'NE8 2BH'
      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      response = assessors_search('SE19SG', 'domesticRdSap')
      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessors'].size).to eq(0)
    end

    it 'shows distance of assessors inside of 1 degree latitude/longitude' do
      add_postcodes('SE1 9SG', 51.5045, 0.0865)

      add_postcodes('SW8 5BN', 51.4818, 0.1444, false)

      scheme_id = add_scheme_and_get_name

      assessor = valid_assessor_with_contact_request_body
      assessor[:searchResultsComparisonPostcode] = 'SW8 5BN'
      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      response = assessors_search('SE19SG', 'domesticRdSap')

      response_json = JSON.parse(response.body)
      expect(
        response_json['data']['assessors'][0]['distanceFromPostcodeInMiles']
      ).to be_between(2, 4)
    end

    it 'does not return inactive assessors' do
      add_postcodes('SE1 5BN', 51.5045, 0.0865)

      scheme_id = add_scheme_and_get_name

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = 'INACTIVE'
      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )
      response = assessors_search('SE15BN', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessors']).to eq([])
    end

    it 'does return reactivated assessors' do
      add_postcodes('SE1 7EZ', 51.5045, 0.0865)

      scheme_id = add_scheme_and_get_name

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = 'INACTIVE'

      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )
      assessor[:qualifications][:domesticRdSap] = 'ACTIVE'

      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      response = assessors_search('SE17EZ', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessors'].size).to eq(1)
    end

    it 'does not return unactivated assessors' do
      add_postcodes('SE1 7EZ', 51.5045, 0.0865)
      scheme_id = add_scheme_and_get_name

      assessor = valid_assessor_with_contact_request_body
      assessor[:qualifications][:domesticRdSap] = 'ACTIVE'

      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      assessor[:qualifications][:domesticRdSap] = 'INACTIVE'
      add_assessor(
        scheme_id,
        'ASSESSOR999',
        valid_assessor_with_contact_request_body
      )

      response = assessors_search('SE17EZ', 'domesticRdSap')

      response_json = JSON.parse(response.body)

      expect(response_json['data']['assessors'].size).to eq(0)
    end

    context 'when the postcode is not found' do
      it 'returns results based on the outcode of the postcode' do
        add_postcodes('SE1 5BN', 51.5045, 0.0865)
        add_outcodes('SE1', 51.5045, 0.4865)
        scheme_id = add_scheme_and_get_name

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = 'SE1 5BN'
        add_assessor(
          scheme_id,
          'ASSESSOR999',
          valid_assessor_with_contact_request_body
        )
        response = assessors_search('SE19SY', 'domesticRdSap')

        response_json = JSON.parse(response.body)
        expect(response_json['data']['assessors'][0]).to include(
          'distanceFromPostcodeInMiles'
        )
      end

      it 'returns error when neither postcode or outcode are found' do
        add_postcodes('SE1 5BN', 51.5045, 0.0865)
        add_outcodes('SE1', 51.5045, 0.4865)
        scheme_id = add_scheme_and_get_name

        assessor = valid_assessor_with_contact_request_body
        assessor[:searchResultsComparisonPostcode] = 'SE1 5BN'
        add_assessor(
          scheme_id,
          'ASSESSOR999',
          valid_assessor_with_contact_request_body
        )
        response = assessors_search('NE19SY', 'domesticRdSap', [404])
        response_json = JSON.parse(response.body)
        expect((response_json).key?('errors')).to eq(true)
      end
    end
  end

  context 'when searching by qualification' do
    context 'for air conditioning level 3 assessors' do
      it 'returns only the assessors qualified' do
        add_postcodes('SE1 7EZ', 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_name

        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:domesticRdSap] = 'INACTIVE'
        assessor[:qualifications][:nonDomesticSp3] = 'ACTIVE'
        add_assessor(scheme_id, 'AIR_CON_ASSESSOR', assessor)

        assessor[:qualifications][:domesticRdSap] = 'ACTIVE'
        assessor[:qualifications][:nonDomesticSp3] = 'INACTIVE'
        add_assessor(scheme_id, 'RDSAP_ASSESSOR', assessor)

        response = assessors_search('SE17EZ', 'nonDomesticSp3')
        response_json = JSON.parse(response.body)
        expect(response_json['data']['assessors'].length).to eq(1)
        expect(
          response_json['data']['assessors'].first['schemeAssessorId']
        ).to eq('AIR_CON_ASSESSOR')
        expect(
          response_json['data']['assessors'].first['qualifications'][
            'nonDomesticSp3'
          ]
        ).to eq('ACTIVE')
      end
    end

    context 'for multiple types of qualification' do
      it 'returns each of the assessors with matching qualifications' do
        add_postcodes('SE1 7EZ', 51.5045, 0.0865)
        scheme_id = add_scheme_and_get_name

        assessor = valid_assessor_with_contact_request_body
        assessor[:qualifications][:nonDomesticSp3] = 'ACTIVE'
        assessor[:qualifications][:nonDomesticCc4] = 'INACTIVE'
        add_assessor(scheme_id, 'AIR_CON_ASSESSOR', assessor)

        assessor[:qualifications][:nonDomesticSp3] = 'INACTIVE'
        assessor[:qualifications][:nonDomesticCc4] = 'ACTIVE'
        add_assessor(scheme_id, 'COMPLEXED_AIR_CON_ASSESSOR', assessor)

        response = assessors_search('SE17EZ', 'nonDomesticSp3,nonDomesticCc4')
        response_json = JSON.parse(response.body)
        returned_assessor_ids =
          response_json['data']['assessors'].map { |a| a['schemeAssessorId'] }
        expect(returned_assessor_ids).to contain_exactly(
          'AIR_CON_ASSESSOR',
          'COMPLEXED_AIR_CON_ASSESSOR'
        )
      end
    end
  end
end
