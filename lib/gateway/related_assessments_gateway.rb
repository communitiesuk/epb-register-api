module Gateway
  class RelatedAssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    def by_address_id(address_id)
      address_id = address_id.gsub("LPRN-", "")
      sql = <<-SQL
        SELECT a.assessment_id,
               a.type_of_assessment AS assessment_type,
               a.date_of_expiry,
               a.date_registered,
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
      if result["assessment_type"] == "RdSAP" || result["assessment_type"] == "SAP"
        result["date_of_expiry"] = result["date_registered"].next_year(10)
      end

      if !result["cancelled_at"].nil?
        result["assessment_status"] = "CANCELLED"
      elsif !result["not_for_issue_at"].nil?
        result["assessment_status"] = "NOT_FOR_ISSUE"
      elsif result["date_of_expiry"] < Date.today.to_time
        result["assessment_status"] = "EXPIRED"
      else
        result["assessment_status"] = "ENTERED"
      end
    end

    end
end
