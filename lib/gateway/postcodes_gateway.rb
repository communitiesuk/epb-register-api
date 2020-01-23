module Gateway
  class PostcodesGateway
    def fetch(postcode)
      response = db_response(postcode)
      result = []

      output(response, result)

      if result.empty?
        outcode_array = postcode.split(' ')
        outcode = outcode_array[0]
        response =
          db_response('outcode', 'postcode_outcode_geolocations', outcode)

        output(response, result, 'outcode')
      end

      result
    end

    private

    def db_response(code = 'postcode', table = 'postcode_geolocation', postcode)
      ActiveRecord::Base.connection.execute(
        "SELECT #{code}, latitude, longitude FROM #{table} WHERE #{code} = '#{
          ActiveRecord::Base.sanitize_sql(postcode)
        }'"
      )
    end

    def output(response, result, postcode = 'postcode')
      response.map do |row|
        result.push(
          {
            "#{postcode}": row[postcode],
            'latitude': row['latitude'].to_f,
            'longitude': row['longitude'].to_f
          }
        )
      end
    end
  end
end
