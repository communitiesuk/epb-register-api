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
            address_id
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

    def row_to_domain(row)
      row.symbolize_keys!
      Domain::AssessmentSearchResult.new(row)
    end
  end
end
