module Gateway
  class RelatedAssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    def by_address_id(address_id)
      return [] if address_id.blank?

      if address_id.include?("UPRN-") || address_id.include?("RRN-")
        sql = <<-SQL
          SELECT a.assessment_id,
                 a.type_of_assessment AS assessment_type,
                 a.date_of_expiry,
                 a.date_registered,
                 a.opt_out
          FROM assessments a
          WHERE address_id = $1 AND
                opt_out = false AND
                not_for_issue_at IS NULL AND
                cancelled_at IS NULL
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
      else
        sql = <<-SQL
          SELECT a.assessment_id,
                 a.type_of_assessment AS assessment_type,
                 a.date_of_expiry,
                 a.date_registered,
                 a.opt_out
          FROM assessments a
          WHERE (address_id = $1 OR address_id = $2) AND
                opt_out = false AND
                not_for_issue_at IS NULL AND
                cancelled_at IS NULL
          ORDER BY date_of_expiry DESC, assessment_id DESC
        SQL

        results =
          ActiveRecord::Base.connection.exec_query(
            sql,
            "SQL",
            [
              ActiveRecord::Relation::QueryAttribute.new(
                "address_id_prefix",
                "LPRN-" + address_id.gsub("LPRN-", ""),
                ActiveRecord::Type::String.new,
              ),
              ActiveRecord::Relation::QueryAttribute.new(
                "address_id_no_prefix",
                address_id.gsub("LPRN-", ""),
                ActiveRecord::Type::String.new,
              ),
            ],
          )
      end

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
      if result["assessment_type"] == "RdSAP" ||
          result["assessment_type"] == "SAP"
        result["date_of_expiry"] = result["date_registered"].next_year(10)
      end

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
