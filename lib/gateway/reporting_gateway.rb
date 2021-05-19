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
          SUBSTRING(a.postcode FROM 1 FOR LENGTH(a.postcode) - 4) = c.outcode
        )
        WHERE
          a.created_at BETWEEN $1 AND $2
        AND (a.migrated IS NULL OR a.migrated IS FALSE)
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

    def assessments_for_open_data(
      date_from,
      type_of_assessment = "",
      task_id = 0,
      date_to = DateTime.now
    )
      report_type = Helper::ExportHelper.report_type_to_s(type_of_assessment)

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_from,
          ActiveRecord::Type::Date.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "task_id",
          task_id,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "report_type",
          report_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "date_to",
          date_to,
          ActiveRecord::Type::Date.new,
        ),
      ]

      sql = <<~SQL
        SELECT  a.assessment_id, a.date_registered, a.created_at, b.region AS postcode_region, c.region AS outcode_region
        FROM assessments a
          LEFT JOIN
            postcode_geolocation b
          ON(a.postcode = b.postcode)
          LEFT JOIN
            postcode_outcode_geolocations c
          ON(
            b.region IS NULL
            AND
            SUBSTRING(a.postcode FROM 1 FOR LENGTH(a.postcode) - 4) = c.outcode
          )
        WHERE a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
        AND a.date_registered BETWEEN $1 AND $4
        AND a.postcode NOT LIKE 'BT%'
        AND NOT EXISTS (SELECT * FROM open_data_logs l
                        WHERE l.assessment_id = a.assessment_id
                        AND task_id = $2 AND report_type = $3
                         )
      SQL

      if type_of_assessment.is_a?(Array)
        valid_type = %w[RdSAP SAP]
        invalid_types = type_of_assessment - valid_type
        raise StandardError, "Invalid types" unless invalid_types.empty?

        list_of_types = type_of_assessment.map { |n| "'#{n}'" }
        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      else
        valid_types = %w[CEPC DEC]
        unless valid_types.include? type_of_assessment
          raise StandardError, "Invalid types"
        end

        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment = '#{type_of_assessment}'
        SQL_TYPE_OF_ASSESSMENT
      end

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)

      results.map { |result| result }
    end

    def assessments_for_open_data_recommendation_report(
      date_from,
      type_of_assessment = "",
      task_id = 0,
      date_to = DateTime.now
    )
      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_from,
          ActiveRecord::Type::Date.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "type_of_assessment",
          type_of_assessment,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "task_id",
          task_id,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "date_to",
          date_to,
          ActiveRecord::Type::Date.new,
        ),
      ]

      sql = <<~SQL
        SELECT  a.assessment_id, date_registered, la.linked_assessment_id
        FROM assessments a
        INNER JOIN linked_assessments la ON a.assessment_id = la.assessment_id
        WHERE a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
        AND a.date_registered BETWEEN $1 AND $4
        AND  type_of_assessment = $2
        AND a.postcode NOT LIKE 'BT%'
        AND NOT EXISTS (SELECT * FROM open_data_logs l
                        WHERE l.assessment_id = a.assessment_id
                        AND task_id = $3 AND report_type = $2
                         )

      SQL

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
      results.map { |result| result }
    end

    def fetch_opted_out_assessments
      sql = <<~SQL
        SELECT assessment_id, type_of_assessment, address_id, address_line1, address_line2, address_line3,
        town, postcode, to_char(date_registered, 'YYYY-MM-DD') as date_registered
        FROM assessments
        WHERE opt_out = true
        AND type_of_assessment IN ('SAP', 'RdSAP', 'CEPC', 'DEC')
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL")
      results.map { |result| result }
    end

  private

    def assessments_for_open_data_defaults
      { type_of_assessment: nil, schema_type: nil, batch: 1, start: 0 }
    end
  end
end
