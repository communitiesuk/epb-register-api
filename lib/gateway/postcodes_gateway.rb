module Gateway
  class PostcodesGateway
    def fetch(postcode)
      salt = rand.to_s

      db = ActiveRecord::Base.connection.raw_connection

      db.prepare(
        'postcode_search'+salt,
        "SELECT latitude, longitude FROM postcode_geolocation WHERE postcode = $1"
      )

      response = db.exec_prepared('postcode_search'+salt, [postcode])

      result = []
      response.each do |row|
        result << row
      end

      result
    end
  end
end
