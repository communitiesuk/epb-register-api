module Gateway
  class PostcodesGateway
    def add(postcode, latitude, longitude)
      db = ActiveRecord::Base.connection.raw_connection

      salt = rand.to_s

      db.prepare(
        'postcode_add' + salt,
        'INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES($1, $2, $3)'
      )

      db.exec_prepared('postcode_add' + salt, [postcode, latitude, longitude])
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
