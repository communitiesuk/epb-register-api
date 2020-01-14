module Gateway
  class PostcodesGateway
    def add(postcode, latitude, longitude)
      db = ActiveRecord::Base

      db.connection.execute(
        "INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES('#{db.sanitize_sql(postcode)}', #{latitude.to_f}, #{longitude.to_f})"
      )
    end

    def truncate
      ActiveRecord::Base.connection.execute(
        'TRUNCATE TABLE postcode_geolocation'
      )
    end

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

      result
    end
  end
end
