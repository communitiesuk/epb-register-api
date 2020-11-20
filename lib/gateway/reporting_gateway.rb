module Gateway
  class ReportingGateway
    def assessments_by_region_and_type(start_date, end_date)
      sql = <<~SQL
        SELECT
          COUNT(type_of_assessment) AS number_of_assessments,
          type_of_assessment,
          COALESCE(b.region, c.region) AS region
        FROM assessments a
        LEFT JOIN
          postcode_geolocation b
        ON(a.postcode = b.postcode)
        LEFT JOIN
          postcode_outcode_geolocations c
        ON(
          b.region IS NULL
          AND
          SUBSTRING(a.postcode, 0, LENGTH(a.postcode) - 3) = c.outcode
        )
        WHERE
          date_registered BETWEEN $1 AND $2
        AND
          (
            cancelled_at IS NULL
            OR
            cancelled_at NOT BETWEEN $1 AND $2
          )
        GROUP BY type_of_assessment, COALESCE(b.region, c.region)
        ORDER BY type_of_assessment, COALESCE(b.region, c.region)
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date,
          ActiveRecord::Type::String.new,
        ),
      ]

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds
      results.map { |result| result }
    end

    def assessments_by_scheme_and_type(start_date, end_date)
      sql = <<~SQL
        SELECT
          COUNT(a.type_of_assessment) AS number_of_assessments,
          c.name AS scheme_name,
          a.type_of_assessment
        FROM assessments a
        LEFT JOIN
          assessors b
        ON(a.scheme_assessor_id = b.scheme_assessor_id)
        LEFT JOIN
          schemes c
        ON(b.registered_by = c.scheme_id)
        WHERE
          created_at BETWEEN $1 AND $2
        AND
          migrated IS NULL
        GROUP BY c.name, a.type_of_assessment
        ORDER BY c.name, a.type_of_assessment
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date,
          ActiveRecord::Type::String.new,
        ),
      ]

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds
      results.map { |result| result }
    end
  end
end
