module Gateway
  class PostcodesGateway
    def fetch(postcode)
      response =
        ActiveRecord::Base.connection.execute(
          "SELECT postcode, latitude, longitude FROM postcode_geolocation WHERE postcode = '#{
            ActiveRecord::Base.sanitize_sql(postcode)
          }'"
        )

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
          ActiveRecord::Base.connection.execute(
            "SELECT outcode, latitude, longitude FROM postcode_outcode_geolocations WHERE outcode = '#{
              ActiveRecord::Base.sanitize_sql(outcode)
            }'"
          )

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
  end
end
