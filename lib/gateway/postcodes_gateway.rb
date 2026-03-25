module Gateway
  class PostcodesGateway
    # postcodes base
    SCOTTISH_BORDER_OUTCODES = %w[
      CA6
      DG14
      DG16
      TD5
      TD8
      TD9
      TD12
      TD15
    ].freeze

    def fetch(postcode, is_scottish: false)
      response = db_response(postcode:, is_scottish: is_scottish)
      result = []

      output(response, result)

      if result.empty?
        outcode = postcode.split(" ")[0]
        response =
          db_response(
            code: "outcode",
            is_scottish: is_scottish,
            table: "postcode_outcode_geolocations",
            postcode: outcode,
          )

        output(response, result, "outcode")
      end

      result
    end

  private

    def db_response(postcode:, is_scottish: false, code: "postcode", table: "postcode_geolocation")
      sql = <<-SQL
        SELECT #{code}, latitude, longitude FROM #{table} WHERE #{code} = $1
      SQL

      unless SCOTTISH_BORDER_OUTCODES.include?(postcode.split(" ")[0])
        sql += if is_scottish
                 " AND region = 'Scotland'"
               else
                 " AND region != 'Scotland'"
               end
      end

      ActiveRecord::Base.connection.exec_query(
        sql,
        "SQL",
        [
          ActiveRecord::Relation::QueryAttribute.new(
            "postcode",
            postcode,
            ActiveRecord::Type::String.new,
          ),
        ],
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
