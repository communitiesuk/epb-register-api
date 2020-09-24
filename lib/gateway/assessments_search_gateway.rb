# frozen_string_literal: true

module Gateway
  class AssessmentsSearchGateway
    class Assessment < ActiveRecord::Base; end

    class InvalidAssessmentType < StandardError; end

    ASSESSMENT_SEARCH_INDEX_SELECT = <<-SQL
        SELECT
            assessment_id, date_of_assessment,type_of_assessment,
            current_energy_efficiency_rating, opt_out, postcode, date_of_expiry, date_registered,
            address_line1, address_line2, address_line3, address_line4, town,
            cancelled_at, not_for_issue_at, address_id, scheme_assessor_id
        FROM assessments
    SQL

    def search_by_postcode(postcode, assessment_types = [])
      sql =
        ASSESSMENT_SEARCH_INDEX_SELECT +
        <<-SQL
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
      sql =
        ASSESSMENT_SEARCH_INDEX_SELECT +
        <<-SQL
        WHERE 
            (
              address_line1 ILIKE $1
              OR
              address_line2 ILIKE $1
            )
            AND (
              town ILIKE $2
              OR
              address_line2 ILIKE $2
              OR
              address_line3 ILIKE $2
              OR
              address_line4 ILIKE $2
            )
        SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          "%" + street_name + "%",
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          "%" + town + "%",
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
        WHERE assessment_id = '#{
            ActiveRecord::Base.sanitize_sql(assessment_id)
          }'
        SQL

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
      symbolised_keys = row.symbolize_keys!
      updated_symbolised_keys = set_expiration_date(symbolised_keys)

      Domain::AssessmentSearchResult.new(updated_symbolised_keys)
    end

    def set_expiration_date(symbolised_keys)
      date_registered = symbolised_keys[:date_registered]
      type_of_assessment = symbolised_keys[:type_of_assessment]

      if type_of_assessment == "RdSAP" || type_of_assessment == "SAP"
        new_date_registered = date_registered.next_year(10)

        updated_date_registered = { date_of_expiry: new_date_registered }
        symbolised_keys = symbolised_keys.merge(updated_date_registered)
      end

      symbolised_keys
    end
  end
end
