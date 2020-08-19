# frozen_string_literal: true

module Gateway
  class AssessmentsSearchGateway
    class Assessment < ActiveRecord::Base; end

    class InvalidAssessmentType < StandardError; end

    def search_by_postcode(postcode, assessment_types = [])
      sql = <<-SQL
        SELECT
            assessment_id, date_of_assessment,
            type_of_assessment, current_energy_efficiency_rating,
            opt_out, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town,
            cancelled_at, not_for_issue_at,
            address_id, scheme_assessor_id
        FROM assessments
        WHERE postcode = $1
        AND cancelled_at IS NULL
        AND not_for_issue_at IS NULL
        AND opt_out = false
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

            ActiveRecord::Base.sanitize_sql(assessment_type)
          end

        sql +=
          " AND type_of_assessment IN('" +
          sanitized_assessment_types.join("', '") + "')"
      end

      response = Assessment.connection.exec_query sql, "SQL", binds

      result = []

      response.each { |row| result << row_to_domain(row) }

      result
    end

    def search_by_street_name_and_town(
      street_name, town, assessment_type, restrictive = true
    )
      sql = <<-SQL
        SELECT
            assessment_id, date_of_assessment,
            type_of_assessment, current_energy_efficiency_rating,
            opt_out, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town,
            cancelled_at, not_for_issue_at,
            address_id, scheme_assessor_id
        FROM assessments
        WHERE (#{
        Helper::LevenshteinSqlHelper.levenshtein(
          'address_line1',
          '$1',
          Helper::LevenshteinSqlHelper::STREET_PERMISSIVENESS,
        )
      } OR #{
        Helper::LevenshteinSqlHelper.levenshtein(
          'address_line2',
          '$1',
          Helper::LevenshteinSqlHelper::STREET_PERMISSIVENESS,
        )
      } OR #{
        Helper::LevenshteinSqlHelper.levenshtein(
          'address_line3',
          '$1',
          Helper::LevenshteinSqlHelper::STREET_PERMISSIVENESS,
        )
      })
                AND (#{
        Helper::LevenshteinSqlHelper.levenshtein(
          'town',
          '$2',
          Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
        )
      } OR #{
        Helper::LevenshteinSqlHelper.levenshtein(
          'address_line2',
          '$2',
          Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
        )
      } OR #{
        Helper::LevenshteinSqlHelper.levenshtein(
          'address_line3',
          '$2',
          Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
        )
      } OR #{
        Helper::LevenshteinSqlHelper.levenshtein(
          'address_line4',
          '$2',
          Helper::LevenshteinSqlHelper::TOWN_PERMISSIVENESS,
        )
      })
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          street_name,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          town,
          ActiveRecord::Type::String.new,
        ),
      ]

      unless assessment_type.nil? || assessment_type.empty?
        ins = []
        assessment_type.each do |type|
          ins.push("'" + ActiveRecord::Base.sanitize_sql(type) + "'")
        end
        sql += " AND type_of_assessment IN(" + ins.join(", ") + ")"
      end

      if restrictive
        sql +=
          ' AND cancelled_at IS NULL
              AND not_for_issue_at IS NULL
              AND opt_out = false'
      end

      sql +=
        " ORDER BY
                #{
          Helper::LevenshteinSqlHelper.levenshtein('address_line1', '$1')
        },
                #{Helper::LevenshteinSqlHelper.levenshtein('town', '$2')},
                address_line1,
                assessment_id"

      response = Assessment.connection.exec_query sql, "SQL", binds

      result = []
      response.each { |row| result << row_to_domain(row) }

      result
    end

    def search_by_assessment_id(
      assessment_id, restrictive = true, assessment_type = []
    )
      sql =
        "SELECT assessment_id, date_of_assessment,
            type_of_assessment, current_energy_efficiency_rating,
            opt_out, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town,
            cancelled_at, not_for_issue_at,
            address_id, scheme_assessor_id

        FROM assessments
        WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }'"

      if restrictive
        sql += " AND cancelled_at IS NULL"
        sql += " AND not_for_issue_at IS NULL"
      end

      unless assessment_type.empty?
        ins = []
        assessment_type.each do |type|
          ins.push("'" + ActiveRecord::Base.sanitize_sql(type) + "'")
        end
        sql += " AND type_of_assessment IN(" + ins.join(", ") + ")"
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
      row.symbolize_keys!
      Domain::AssessmentSearchResult.new(row)
    end
  end
end
