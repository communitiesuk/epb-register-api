module Gateway
  class Postcodes
    def search(postcode);
        salt = rand.to_s

      ActiveRecord::Base.connection.raw_connection.prepare(
      'postcode_search'+salt,  "SELECT latitude, longitude FROM postcode_geolocation WHERE postcode = $1"
      )
      response = ActiveRecord::Base.connection.raw_connection.exec_prepared('postcode_search'+salt, [postcode])
      result = []
      response.each do |row|
        result << row
      end
      result
    end
  end
end
