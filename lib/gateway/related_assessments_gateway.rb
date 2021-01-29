module Gateway
  class RelatedAssessmentsGateway
    class Assessment < ActiveRecord::Base
    end

    def by_address_id(address_id)
      return [] if address_id.blank?

      assessment_ids =
        ActiveRecord::Base
          .connection
          .exec_query(
            "SELECT assessment_id FROM assessments_address_id WHERE address_id = $1",
            "SQL",
            [
              ActiveRecord::Relation::QueryAttribute.new(
                "address_id",
                address_id,
                ActiveRecord::Type::String.new,
              ),
            ],
          )
          .map do |assessment_id|
            ActiveRecord::Base.connection.quote(assessment_id["assessment_id"])
          end

      return [] if assessment_ids.empty?

      sql = <<-SQL
        SELECT assessment_id,
               type_of_assessment AS assessment_type,
               date_of_expiry,
               date_registered,
               opt_out
        FROM assessments
        WHERE assessment_id IN(#{assessment_ids.join(', ')}) AND
              opt_out = false AND
              not_for_issue_at IS NULL AND
              cancelled_at IS NULL
        ORDER BY date_of_expiry DESC, assessment_id DESC
      SQL

      results = ActiveRecord::Base.connection.execute(sql)

      output =
        results.map do |result|
          determine_status(result)
          Domain::RelatedAssessment.new(
            assessment_id: result["assessment_id"],
            assessment_status: result["assessment_status"],
            assessment_type: result["assessment_type"],
            assessment_expiry_date: result["date_of_expiry"],
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
