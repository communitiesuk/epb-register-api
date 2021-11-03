module Gateway
  class AssessmentStatisticsGateway
    def save(assessments_count:, assessment_type:, rating_average:, day_date:, transaction_type:)
      insert_sql = <<-SQL
            INSERT INTO assessment_statistics(assessments_count, assessment_type, rating_average, day_date, transaction_type)
            VALUES ($1, $2, $3, $4, $5)
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
          "transaction_type",
          transaction_type,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
    end
  end
end
