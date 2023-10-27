module Gateway
  class BackfillDataWarehouseGateway
    def get_rrn_date(rrn)
      sql = <<-SQL
      SELECT date_registered
      FROM assessments
      WHERE assessment_id=$1
      SQL

      attributes = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          rrn,
          ActiveRecord::Type::String.new,
        ),
      ]
      ActiveRecord::Base.connection.exec_query sql, "SQL", attributes
    end

    def get_assessments_id(start_date:, type_of_assessment: nil, end_date: Time.now.utc)
      sql = <<-SQL
      SELECT a.assessment_id
      FROM assessments AS a
        INNER JOIN assessments_xml AS ax ON a.assessment_id=ax.assessment_id
      WHERE date_registered
        BETWEEN $1 AND $2
        AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
      SQL
      attributes = [
        ActiveRecord::Relation::QueryAttribute.new(
          "from",
          start_date,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "to",
          end_date,
          ActiveRecord::Type::DateTime.new,
        ),
      ]
      unless type_of_assessment.nil?
        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment = '#{type_of_assessment}'
        SQL_TYPE_OF_ASSESSMENT
      end

      result = ActiveRecord::Base.connection.exec_query sql, "SQL", attributes
      result.map { |rows| rows["assessment_id"] }
    end
  end
end
