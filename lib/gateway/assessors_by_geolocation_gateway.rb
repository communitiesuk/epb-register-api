module Gateway
  class AssessorsByGeolocationGateway
    def search(latitude, longitude)

      db = ActiveRecord::Base.connection.raw_connection

      salt = rand.to_s

      db.prepare(
        "assessors_by_geolocation"+salt,
        "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email,
          search_results_comparison_postcode,
          (
            sqrt(abs(POWER(69.1 * (a.latitude - $1 ), 2) +
            POWER(69.1 * (a.longitude - $2 ) * cos( $1 / 57.3), 2)))
          ) AS distance

        FROM postcode_geolocation a
        INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
        WHERE
          a.latitude BETWEEN $3 AND $4
          AND a.longitude BETWEEN $5 AND $6

        ORDER BY distance LIMIT 100"
      )

      puts latitude
      puts longitude
      puts "ABOVE"

      response = db.exec_prepared('assessors_by_geolocation'+salt, [latitude, longitude,
                                                                    (latitude - 1),
                                                                    (latitude + 1),
                                                                    (longitude - 1),
                                                                    (longitude + 1)])

      result = []
      response.each do |row|
        result << row
      end

      result
    end
  end
end
