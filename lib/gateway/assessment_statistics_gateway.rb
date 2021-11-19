module Gateway
  class AssessmentStatisticsGateway
    def save(assessments_count:, assessment_type:, rating_average:, day_date:, transaction_type:, country: "")
      insert_sql = <<-SQL
            INSERT INTO assessment_statistics(assessments_count, assessment_type, rating_average, day_date, transaction_type, country)
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
          "transaction_type",
          transaction_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "country",
          country,
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
              SELECT SUM(assessments_count) as num_assessments, assessment_type,  AVG(rating_average) as rating_average, to_char(day_date, 'YYYY-MM') as month
              FROM assessment_statistics a
              WHERE to_char(day_date, 'YYYY-MM') != to_char(now(), 'YYYY-MM')
              GROUP BY to_char(day_date, 'YYYY-MM'), assessment_type
              ORDER BY to_char(day_date, 'YYYY-MM') desc;

      SQL

      ActiveRecord::Base.connection.exec_query(sql)
    end

    def fetch_monthly_stats_by_country
      sql = <<-SQL
              SELECT SUM(assessments_count) as num_assessments, assessment_type,  AVG(rating_average) as rating_average, to_char(day_date, 'YYYY-MM') as month, country
              FROM assessment_statistics a
              WHERE to_char(day_date, 'YYYY-MM') != to_char(now(), 'YYYY-MM')
              GROUP BY to_char(day_date, 'YYYY-MM'), assessment_type, country
              ORDER BY to_char(day_date, 'YYYY-MM') desc;
      SQL

      ActiveRecord::Base.connection.exec_query(sql)
    end
  end
end
