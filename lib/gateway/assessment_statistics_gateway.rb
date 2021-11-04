module Gateway
  class AssessmentStatisticsGateway
    def save(assessments_count:, assessment_type:, rating_average:, day_date:, scheme_id:, transaction_type:)
      insert_sql = <<-SQL
            INSERT INTO assessment_statistics(assessments_count, assessment_type, rating_average, day_date, scheme_id, transaction_type)
            VALUES ($1, $2, $3, $4, $5, $6)
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "event_type",
          assessments_count,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_type",
          assessment_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "rating_average",
          rating_average,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "day_date",
          day_date,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "scheme_id",
          scheme_id,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "transaction_type",
          transaction_type,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
    end

    def min_assessment_date
      sql = <<-SQL
              SELECT MIN(a.day_date) as day_date
              FROM assessment_statistics a
      SQL

      min_date = ActiveRecord::Base.connection.exec_query(sql).first["day_date"]
      return (Time.now.to_date - 1) if min_date.nil?

      min_date
    end
  end
end
