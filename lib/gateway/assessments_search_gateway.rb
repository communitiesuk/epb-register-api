# frozen_string_literal: true

module Gateway
  class AssessmentsSearchGateway
    class Assessment < ActiveRecord::Base; end

    class InvalidAssessmentType < StandardError; end

    ASSESSMENT_SEARCH_INDEX_SELECT = <<-SQL
        SELECT
            a.assessment_id, a.date_of_assessment, a.type_of_assessment,
            a.current_energy_efficiency_rating, a.opt_out, a.postcode, a.date_of_expiry, a.date_registered,
            a.address_line1, a.address_line2, a.address_line3, a.address_line4, a.town,
            a.cancelled_at, a.not_for_issue_at, b.address_id, a.scheme_assessor_id
        FROM assessments a
        LEFT JOIN assessments_address_id b
            ON(a.assessment_id = b.assessment_id)
    SQL

    def search_by_postcode(postcode, assessment_types = [])
      sql =
        ASSESSMENT_SEARCH_INDEX_SELECT +
        <<-SQL
        WHERE a.postcode = $1
        AND a.cancelled_at IS NULL
        AND a.not_for_issue_at IS NULL
        AND a.opt_out = false
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
            unless %w[
              RdSAP
              SAP
              CEPC
              CEPC-RR
              DEC
              DEC-RR
              AC-CERT
              AC-REPORT
            ].include? assessment_type
              raise InvalidAssessmentType
            end

            ActiveRecord::Base.connection.quote(assessment_type)
          end

        sql +=
          " AND type_of_assessment IN(" +
          sanitized_assessment_types.join(", ") + ")"
      end

      response = Assessment.connection.exec_query sql, "SQL", binds

      result = []

      response.each { |row| result << row_to_domain(row) }

      result
    end

    def search_by_street_name_and_town(
      street_name, town, assessment_type, restrictive = true
    )
      sql = ASSESSMENT_SEARCH_INDEX_SELECT + " WHERE "

      unless assessment_type.nil? || assessment_type.empty?
        ins = []
        assessment_type.each do |type|
          ins.push(ActiveRecord::Base.connection.quote(type))
        end
        sql += "a.type_of_assessment IN(" + ins.join(", ") + ") AND "
      end

      sql +=
        <<-SQL
            (
              LOWER(a.town) = $2
              OR
              LOWER(a.address_line2) = $2
              OR
              LOWER(a.address_line3) = $2
              OR
              LOWER(a.address_line4) = $2
            )
            AND
            (
              LOWER(a.address_line1) LIKE $1
              OR
              LOWER(a.address_line2) LIKE $1
            )
        SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          "%" + street_name.downcase + "%",
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          town.downcase,
          ActiveRecord::Type::String.new,
        ),
      ]

      if restrictive
        sql +=
          ' AND a.cancelled_at IS NULL
              AND a.not_for_issue_at IS NULL
              AND a.opt_out = false'
      end

      sql += " LIMIT 200"

      response = Assessment.connection.exec_query sql, "SQL", binds

      result = []
      response.each { |row| result << row_to_domain(row) }

      result
    end

    def search_by_assessment_id(
      assessment_id, restrictive = true, assessment_type = []
    )
      sql =
        ASSESSMENT_SEARCH_INDEX_SELECT +
        <<-SQL
        WHERE a.assessment_id = #{
            ActiveRecord::Base.connection.quote(assessment_id)
          }
        SQL

      if restrictive
        sql += " AND a.cancelled_at IS NULL"
        sql += " AND a.not_for_issue_at IS NULL"
      end

      unless assessment_type.empty?
        ins = []
        assessment_type.each do |type|
          ins.push(ActiveRecord::Base.connection.quote(type))
        end
        sql += " AND a.type_of_assessment IN(" + ins.join(", ") + ")"
      end

      response = Assessment.connection.execute(sql)

      result = []
      response.each do |row|
        search_domain = row_to_domain(row)
        result << search_domain
      end

      result
    end

    def row_to_domain(row)
      Domain::AssessmentSearchResult.new(row.symbolize_keys)
    end
  end
end
