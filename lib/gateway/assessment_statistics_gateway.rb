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

    def min_assessment_date
      sql = <<-SQL
              SELECT MIN(a.day_date) as day_date
              FROM assessment_statistics a
      SQL

      min_date = ActiveRecord::Base.connection.exec_query(sql).first["day_date"]
      return (Time.now.to_date - 1) if min_date.nil?

      min_date
    end

    def fetch_monthly_stats
      sql = <<-SQL
              SELECT SUM(assessments_count) as num_assessments, assessment_type,  AVG(rating_average) as rating_average, to_char(day_date, 'MM-YYYY') as month_year
              FROM assessment_statistics a
              GROUP BY assessment_type, to_char(day_date, 'MM-YYYY')

      SQL
      results = ActiveRecord::Base.connection.exec_query(sql)
      results.map { |result| result }
    end
  end
end
