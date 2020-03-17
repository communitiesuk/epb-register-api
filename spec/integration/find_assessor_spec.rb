describe 'Integration::FilterAndOrderAssessorsByPostcode' do
  include RSpecAssessorServiceMixin

  def truncate(postcode = nil)
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

  def add_postcodes(postcode, latitude = 0, longitude = 0, clean = true)
    db = ActiveRecord::Base

    truncate(postcode) if clean

    db.connection.execute(
      "INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES('#{
        db.sanitize_sql(postcode)
      }', #{latitude.to_f}, #{longitude.to_f})"
    )
  end

  def add_assessor(scheme_id, assessor_id, body)
    put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
  end

  def add_scheme(name = 'test scheme')
    JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
  end

  let(:valid_assessor_request_body) do
    {
      firstName: 'Someone',
      middleNames: 'muddle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      searchResultsComparisonPostcode: 'BF1 3AD',
      qualifications: { domesticRdSap: 'ACTIVE' }
    }
  end

  def populate_postcode_geolocation
    postcode_gateway = Gateway::PostcodesGateway.new

    truncate
    add_postcodes('BF1 3AD', 27.7172, -85.3240)
  end

  context 'when searching for a postcode' do
    context 'and postcode_geolocation table is empty' do
      it 'returns an empty hash' do
        response = Gateway::PostcodesGateway.new.fetch('BF1 3AD')
        expect(response).to eq([])
      end
    end

    context 'and postcode_geolocation table is not empty' do
      it 'returns a single record' do
        populate_postcode_geolocation

        response = Gateway::PostcodesGateway.new.fetch('BF1 3AD')

        expect(response).to eq(
          [
            {
              'postcode': 'BF1 3AD', 'latitude': 27.7172, 'longitude': -85.3240
            }
          ]
        )
      end
    end
  end

  context 'when ordering and filtering assessors by postcode' do
    it 'the returned assessor is within 0.0 distance' do
      scheme_id = authenticate_and { add_scheme }

      authenticate_and do
        add_assessor(scheme_id, 'SCHEME4233', valid_assessor_request_body)
      end

      populate_postcode_geolocation

      postcode = Gateway::PostcodesGateway.new.fetch('BF1 3AD').first

      assessors =
        Gateway::AssessorsGateway.new.search(
          postcode[:latitude],
          postcode[:longitude],
          'domesticRdSap'
        )

      expect(assessors.first[:distance]).to eq(0.0)
    end
  end
end
