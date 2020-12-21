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

    def assessments_by_scheme_and_type(start_date, end_date, scheme_id = nil)
      sql = <<~SQL
        SELECT a.assessment_id,
               c.name AS scheme_name,
               a.type_of_assessment,
               a.created_at,
               la.linked_assessment_id AS linked
        FROM assessments a
        INNER JOIN assessors b ON a.scheme_assessor_id = b.scheme_assessor_id
        INNER JOIN schemes c ON b.registered_by = c.scheme_id
        LEFT JOIN linked_assessments la ON la.assessment_id = a.assessment_id
        WHERE a.created_at BETWEEN $1 AND $2
          AND (a.migrated IS NULL OR a.migrated IS FALSE)
          AND (la.assessment_id IS NULL OR a.assessment_id > la.linked_assessment_id)
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

      unless scheme_id.nil?
        sql << " AND c.scheme_id = $3"

        binds << ActiveRecord::Relation::QueryAttribute.new(
          "scheme_id",
          scheme_id,
          ActiveRecord::Type::String.new,
        )
      end

      sql << " ORDER BY a.created_at"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds
      results.map { |result| result }
    end
  end
end
