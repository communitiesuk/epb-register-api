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

        binds <<
          ActiveRecord::Relation::QueryAttribute.new(
            "scheme_id",
            scheme_id,
            ActiveRecord::Type::String.new,
          )
      end

      sql << " ORDER BY a.created_at"

      results = ActiveRecord::Base.connection.exec_query sql, "SQL", binds
      results.map { |result| result }
    end

    def assessments_xml_for_open_data(args = {})
      args = assessments_for_open_data_defaults.merge(args)

      # where = " a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL"
      #
      # if args[:type_of_assessment]
      #   where <<
      #     " AND a.type_of_assessment = " +
      #       ActiveRecord::Base.connection.quote(args[:type_of_assessment])
      # end
      #
      # if args[:schema_type]
      #   where <<
      #     " AND b.schema_type = " +
      #       ActiveRecord::Base.connection.quote(args[:schema_type])
      # end

      sql = <<~SQL
        SELECT  a.assessment_id, b.schema_type, c.address_id
         FROM assessments a
         INNER JOIN assessments_xml b ON(a.assessment_id = b.assessment_id)
         INNER JOIN assessments_address_id c  ON(a.assessment_id = c.assessment_id)
         WHERE a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
         ORDER BY a.date_registered
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "type_of_assessment",
          args[:type_of_assessment],
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "schema_type",
          args[:schema_type],
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "limit",
          args[:batch],
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "start",
          args[:start],
          ActiveRecord::Type::Integer.new,
        ),
      ]

      results = ActiveRecord::Base.connection.exec_query sql
      results.map { |result| result }
    end

    def assessments_for_open_data(args = {})
      args = assessments_for_open_data_defaults.merge(args)

      sql = <<~SQL
        SELECT  a.assessment_id, created_at
        FROM assessments a
        INNER JOIN assessments_address_id c  ON(a.assessment_id = c.assessment_id)
        INNER JOIN assessments_xml b ON(a.assessment_id = b.assessment_id)
        WHERE a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
        ORDER BY a.assessment_id

      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "type_of_assessment",
          args[:type_of_assessment],
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "schema_type",
          args[:schema_type],
          ActiveRecord::Type::String.new,
        ),
      ]

      results = ActiveRecord::Base.connection.exec_query(sql)
      results.map { |result| result }
    end


    def assessments_for_open_data_recommendation_report(type_of_assessment)

      bindings = [[nil, type_of_assessment]]

      sql = <<~SQL
        SELECT  a.assessment_id, created_at
        FROM assessments a
        INNER JOIN assessments_xml xml ON(a.assessment_id = xml.assessment_id)
        JOIN linked_assessments la ON a.assessment_id = la.assessment_id
        WHERE a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
        AND a.type_of_assessment = $1
        ORDER BY a.assessment_id
      SQL


      results = ActiveRecord::Base.connection.exec_query(sql, 'SQL', bindings)
      results.map { |result| result }
    end

  private

    def assessments_for_open_data_defaults
      { type_of_assessment: nil, schema_type: nil, batch: 1, start: 0 }
    end
  end
end
