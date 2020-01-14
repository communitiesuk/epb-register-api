module Gateway
  class PostcodesGateway
    def fetch(postcode)
      salt = rand.to_s

      db = ActiveRecord::Base.connection.raw_connection

      db.prepare(
        'postcode_search' + salt,
        'SELECT postcode, latitude, longitude FROM postcode_geolocation WHERE postcode = $1'
      )

      response = db.exec_prepared('postcode_search' + salt, [postcode])

      result = []
      response.map do |row|
        result.push({
          'postcode': row['postcode'],
          'latitude': row['latitude'].to_f,
          'longitude': row['longitude'].to_f
        })
      end

      result
    end
  end
end
