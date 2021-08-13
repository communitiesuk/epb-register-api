module Gateway
  class PostcodesGateway
    def fetch(postcode)
      response = db_response(postcode: postcode)
      result = []

      output(response, result)

      if result.empty?
        outcode_array = postcode.split(" ")
        outcode = outcode_array[0]
        response =
          db_response(
            code: "outcode",
            table: "postcode_outcode_geolocations",
            postcode: outcode,
          )

        output(response, result, "outcode")
      end

      result
    end

  private

    def db_response(postcode:, code: "postcode", table: "postcode_geolocation")
      ActiveRecord::Base.connection.exec_query(
        "SELECT #{code}, latitude, longitude FROM #{table} WHERE #{code} = #{
          ActiveRecord::Base.connection.quote(postcode)
        }",
      )
    end

    def output(response, result, postcode = "postcode")
      response.map do |row|
        result.push(
          {
            "#{postcode}": row[postcode],
            'latitude': row["latitude"].to_f,
            'longitude': row["longitude"].to_f,
          },
        )
      end
    end
  end
end
