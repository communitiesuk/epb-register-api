module Gateway
  class FilteredAssessorsByPostcodeGateway
    def search(latitude, longitude);

      db = ActiveRecord::Base.connection

      db.execute("SELECT *,
      (
          sqrt(abs(POWER(69.1 * (a.latitude - "+latitude+"), 2) + POWER(69.1 * (a.longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
      ) AS distance

      FROM postcode_geolocation a
      INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
      WHERE
      a.latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
      AND a.longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

      ORDER BY distance LIMIT 100")
    end
  end
end
