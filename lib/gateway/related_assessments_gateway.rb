module Gateway
  class RelatedAssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    def by_address_id(address_id)
      sql = <<-SQL
        SELECT a.assessment_id,
               a.type_of_assessment AS assessment_type,
               a.date_of_expiry,
               CASE WHEN a.cancelled_at IS NOT NULL THEN 'CANCELLED'
                    WHEN a.not_for_issue_at IS NOT NULL THEN 'NOT_FOR_ISSUE'
                    WHEN a.date_of_expiry < CURRENT_DATE THEN 'EXPIRED'
                    ELSE 'ENTERED'
                   END AS assessment_status,
              a.opt_out
        FROM assessments a
        WHERE address_id = $1 AND
              opt_out = false
        ORDER BY date_of_expiry DESC, assessment_id DESC
      SQL

      results =
        ActiveRecord::Base.connection.exec_query(
          sql,
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "address_id",
              address_id,
              ActiveRecord::Type::String.new,
            ),
          ],
        )

      output =
        results.map do |result|
          Domain::RelatedAssessment.new(
            assessment_id: result["assessment_id"],
            assessment_status: result["assessment_status"],
            assessment_type: result["assessment_type"],
            assessment_expiry_date: result["date_of_expiry"],
          )
        end

      output.compact
    end
  end
end
