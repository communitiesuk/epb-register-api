# frozen_string_literal: true

module Gateway
  class AssessmentsSearchGateway
    include ReadOnlyDatabaseAccess

    class Assessment < ActiveRecord::Base
    end

    class InvalidAssessmentType < StandardError
    end

    def assessment_search_index_select(schema)
      <<-SQL
        SELECT
            a.assessment_id, a.date_of_assessment, a.type_of_assessment,
            a.current_energy_efficiency_rating, a.opt_out, a.postcode, a.date_of_expiry, a.date_registered,
            a.address_line1, a.address_line2, a.address_line3, a.address_line4, a.town, a.created_at,
            a.cancelled_at, a.not_for_issue_at, b.address_id, a.scheme_assessor_id, la.linked_assessment_id
        FROM #{schema}assessments a
        INNER JOIN #{schema}assessments_address_id b USING(assessment_id)
        LEFT JOIN #{schema}linked_assessments la USING(assessment_id)
      SQL
    end

    VALID_ASSESSMENT_TYPES = %w[
      RdSAP
      SAP
      CEPC
      CEPC-RR
      DEC
      DEC-RR
      DEC-AR
      AC-CERT
      AC-REPORT
      CS63
    ].freeze

    def search_by_postcode(postcode, assessment_types = [], is_scottish: false)
      schema = Helper::ScotlandHelper.select_schema(is_scottish)

      sql = assessment_search_index_select(schema) + <<-SQL
        WHERE a.postcode = $1
        AND a.cancelled_at IS NULL
        AND a.not_for_issue_at IS NULL
        AND a.opt_out = FALSE
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "postcode",
          postcode,
          ActiveRecord::Type::String.new,
        ),
      ]

      unless assessment_types.nil? || assessment_types.empty?
        sanitized_assessment_types =
          assessment_types.map do |assessment_type|
            raise InvalidAssessmentType unless VALID_ASSESSMENT_TYPES.include? assessment_type

            ActiveRecord::Base.connection.quote(assessment_type)
          end

        sql +=
          " AND type_of_assessment IN(#{sanitized_assessment_types.join(', ')})"
      end

      result = []

      read_only do
        result = ActiveRecord::Base.connection.exec_query sql, "SQL", binds
      end

      result.map { |row| row_to_domain(row) }
    end

    def search_by_street_name_and_town(
      street_name,
      town,
      assessment_type,
      restrictive: true,
      limit: nil,
      is_scottish: false
    )
      schema = Helper::ScotlandHelper.select_schema(is_scottish)

      sql_cte = <<-SQL
        WITH cte AS (
          SELECT a.assessment_id,
          a.date_of_assessment,
          a.type_of_assessment,
          a.current_energy_efficiency_rating,
          a.opt_out,
          a.postcode,
          a.date_of_expiry,
          a.date_registered,
          a.address_line1,
          a.address_line2,
          a.address_line3,
          a.address_line4,
          a.town,
          a.created_at,
          a.cancelled_at,
          a.not_for_issue_at,
          a.scheme_assessor_id
        FROM #{schema}assessments a
        JOIN #{schema}assessment_search_address sa ON a.assessment_id = sa.assessment_id
        WHERE sa.address LIKE $1
      SQL

      unless assessment_type.nil? || assessment_type.empty?
        ins = []
        assessment_type.each do |type|
          ins.push(ActiveRecord::Base.connection.quote(type))
        end
        sql_cte += " AND a.type_of_assessment IN(#{ins.join(', ')}) "
      end

      if restrictive
        sql_cte +=
          ' AND a.cancelled_at IS NULL
              AND a.not_for_issue_at IS NULL
              AND a.opt_out = FALSE'
      end

      sql = sql_cte + <<-SQL
          )
           SELECT cte.*, b.address_id, la.linked_assessment_id
           FROM cte
           INNER JOIN #{schema}assessments_address_id b USING (assessment_id)
           LEFT JOIN #{schema}linked_assessments la USING (assessment_id)
           WHERE ( LOWER(cte.town) = $2  OR  LOWER(cte.address_line2) = $2
           OR  LOWER(cte.address_line3) = $2
           OR  LOWER(cte.address_line4) = $2)
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          "%#{street_name.downcase}%",
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          town.downcase,
          ActiveRecord::Type::String.new,
        ),
      ]

      if limit
        sql += " LIMIT #{limit.to_i}"
      end

      result = []

      read_only do
        result = Assessment.connection.exec_query sql, "SQL", binds
      end

      result.map { |row| row_to_domain(row) }
    end

    def search_by_assessment_id(
      assessment_id,
      restrictive: true,
      is_scottish: false
    )
      schema = Helper::ScotlandHelper.select_schema(is_scottish)

      sql = assessment_search_index_select(schema) + <<-SQL
        WHERE a.assessment_id = #{
        ActiveRecord::Base.connection.quote(assessment_id)
      }
      SQL

      if restrictive
        sql += " AND a.cancelled_at IS NULL"
        sql += " AND a.not_for_issue_at IS NULL"
      end

      result = Assessment.connection.exec_query(sql)

      result.map { |row| row_to_domain(row) }
    end

    def row_to_domain(row)
      Domain::AssessmentSearchResult.new(**row.symbolize_keys)
    end
  end
end
