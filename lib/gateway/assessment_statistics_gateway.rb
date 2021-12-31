module Gateway
  class AssessmentStatisticsGateway
    VALID_ASSESSMENT_TYPES = %w[
      RdSAP
      SAP
      CEPC
      CEPC-RR
      DEC
      DEC-RR
      AC-CERT
      AC-REPORT
    ].freeze

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

    def save_daily_stats(date:, assessment_types: nil)
      sql = <<-SQL
        INSERT INTO  assessment_statistics(assessments_count, assessment_type, rating_average, day_date, country)
         SELECT COUNT(assessment_id),
                type_of_assessment,
                AVG(current_energy_efficiency_rating),
                 CAST(to_char(created_at, 'YYYY-MM-DD') AS Date),
                CASE WHEN a.postcode LIKE 'BT%' THEN 'Northern Ireland' ELSE 'England & Wales' END as country
           FROM assessments a
           WHERE to_char(created_at, 'YYYY-MM-DD') = $1 AND migrated IS NOT TRUE

      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date",
          date,
          ActiveRecord::Type::String.new,
        ),
      ]

      if assessment_types.is_a?(Array)
        invalid_types = assessment_types - VALID_ASSESSMENT_TYPES
        raise StandardError, "Invalid types" unless invalid_types.empty?

        list_of_types = assessment_types.map { |n| "'#{n}'" }
        sql += <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      end

      sql += <<~SQL_GROUP
        GROUP BY to_char(created_at, 'YYYY-MM-DD'), type_of_assessment, country;
      SQL_GROUP

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end
  end
end
