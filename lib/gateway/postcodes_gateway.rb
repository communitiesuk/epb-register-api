module Gateway
  class PostcodesGateway
    def fetch(postcode)
      response = db_response(postcode)
      result = []
      response.map do |row|
        result.push(
          {
            'postcode': row['postcode'],
            'latitude': row['latitude'].to_f,
            'longitude': row['longitude'].to_f
          }
        )
      end
      if result.empty?
        outcode_array = postcode.split(' ')
        outcode = outcode_array[0]
        response =
          db_response('outcode', 'postcode_outcode_geolocations', outcode)

        response.map do |row|
          result.push(
            {
              'outcode': row['outcode'],
              'latitude': row['latitude'].to_f,
              'longitude': row['longitude'].to_f
            }
          )
        end
      end
      result
    end

    private

    def db_response(code = 'postcode', table = 'postcode_geolocation', postcode)
      response =
        ActiveRecord::Base.connection.execute(
          "SELECT #{code}, latitude, longitude FROM #{table} WHERE #{code} = '#{
            ActiveRecord::Base.sanitize_sql(postcode)
          }'"
        )
    end
  end
end
