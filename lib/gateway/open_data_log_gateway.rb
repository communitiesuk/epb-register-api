module Gateway
  class OpenDataLogGateway
    def insert(assessment_id, task_id, report_type)
      insert_sql = <<-SQL
            INSERT INTO open_data_logs(assessment_id, created_at, task_id, report_type)
            VALUES ($1, $2, $3, $4)
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "created_at",
          DateTime.now,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "task_id",
          task_id,
          ActiveRecord::Type::BigInteger.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "report_type",
          report_type,
          ActiveRecord::Type::String.new,
          ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
      assessment_id
    end

    def get_log_statistics
      sql = <<-SQL
              SELECT task_id, Count(*) as num_rows, Min(created_at) as date_start, Max(created_at) as date_end, (Max(created_at) - Min(created_at)) as execution_time, report_type
              FROM open_data_logs
              GROUP BY task_id, report_type
              ORDER BY  Max(created_at)
      SQL
      results = ActiveRecord::Base.connection.exec_query(sql)
      results.map { |result| result }
    end
  end
end
