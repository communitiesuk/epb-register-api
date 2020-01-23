module Gateway
  class PostcodesGateway
    def add(postcode, latitude, longitude)
      db = ActiveRecord::Base

      db.connection.execute(
        "INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES('#{
          db.sanitize_sql(postcode)
        }', #{latitude.to_f}, #{longitude.to_f})"
      )
    end

    def add_outcodes(outcode, latitude, longitude)
      db = ActiveRecord::Base

      db.connection.execute(
        "INSERT INTO postcode_outcode_geolocations (outcode, latitude, longitude) VALUES('#{
          db.sanitize_sql(outcode)
        }', #{latitude.to_f}, #{longitude.to_f})"
      )
    end


    def truncate
      ActiveRecord::Base.connection.execute(
        'TRUNCATE TABLE postcode_geolocation'
      )
    end

    def truncate_outcode
      ActiveRecord::Base.connection.execute(
        'TRUNCATE TABLE postcode_outcode_geolocations'
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
