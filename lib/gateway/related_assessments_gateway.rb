module Gateway
  class RelatedAssessmentsGateway
    class Assessment < ActiveRecord::Base
    end

    def related_assessment_ids(address_id, is_scottish: false)
      return [] if address_id.blank?

      schema = Helper::ScotlandHelper.select_schema(is_scottish)

      ActiveRecord::Base
        .connection
        .exec_query(
          "SELECT assessment_id FROM #{schema}assessments_address_id WHERE address_id = $1",
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "address_id",
              address_id,
              ActiveRecord::Type::String.new,
            ),
          ],
        ).map do |row|
          row["assessment_id"]
        end
    end

    def by_address_id(address_id)
      assessment_ids = related_assessment_ids(address_id).map do |assessment_id|
        ActiveRecord::Base.connection.quote(assessment_id)
      end

      return [] if assessment_ids.empty?

      # The ORDER BY here falls back to created_at for cases where registration
      # date are equal.
      # NOTE: This is only reliable for unmigrated certificates
      # For migrated certificates, where the created_at value will be NULL,
      # there is an additional sort on date_of_assessment as a tiebreak.
      sql = <<-SQL
        SELECT assessment_id,
               type_of_assessment AS assessment_type,
               date_of_expiry,
               date_registered,
               created_at,
               opt_out
        FROM assessments
        WHERE assessment_id IN(#{assessment_ids.join(', ')}) AND
              not_for_issue_at IS NULL AND
              cancelled_at IS NULL
        ORDER BY date_registered DESC, created_at DESC, date_of_assessment DESC, assessment_id DESC
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      output =
        results.map do |result|
          determine_status(result)
          Domain::RelatedAssessment.new(
            assessment_id: result["assessment_id"],
            assessment_status: result["assessment_status"],
            assessment_type: result["assessment_type"],
            assessment_expiry_date: result["date_of_expiry"],
            opt_out: result["opt_out"],
          )
        end
      output.compact
    end

    def determine_status(result)
      result["assessment_status"] =
        if !result["cancelled_at"].nil?
          "CANCELLED"
        elsif !result["not_for_issue_at"].nil?
          "NOT_FOR_ISSUE"
        elsif result["date_of_expiry"] < Date.today.to_time
          "EXPIRED"
        else
          "ENTERED"
        end
    end
  end
end
