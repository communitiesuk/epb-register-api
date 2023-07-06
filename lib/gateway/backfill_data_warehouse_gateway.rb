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

    def count_assessments_to_export(rrn_date, start_date, schema_type)
      sql = <<-SQL
      SELECT COUNT(a.assessment_id)
      FROM assessments AS a
          INNER JOIN assessments_xml AS ax ON a.assessment_id=ax.assessment_id
      WHERE date_registered
          BETWEEN $1 AND $2 AND schema_type = $3
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
          rrn_date,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "schema_type",
          schema_type,
          ActiveRecord::Type::String.new,
        ),
      ]
      result = ActiveRecord::Base.connection.exec_query sql, "SQL", attributes
      result.first["count"].to_i
    end

    def get_assessments_id(rrn_date:, start_date:, schema_type:)
      sql = <<-SQL
      SELECT a.assessment_id
      FROM assessments AS a
        INNER JOIN assessments_xml AS ax ON a.assessment_id=ax.assessment_id
      WHERE date_registered
        BETWEEN $1 AND $2 AND schema_type = $3
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
          rrn_date,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "schema_type",
          schema_type,
          ActiveRecord::Type::String.new,
        ),
      ]
      result = ActiveRecord::Base.connection.exec_query sql, "SQL", attributes
      result.map { |rows| rows["assessment_id"] }
    end
  end
end
