module Gateway
  class OpenDataLogGateway
    def create(assessment_id, task_id, report_type)
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
          Time.now.utc,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "task_id",
          task_id,
          ActiveRecord::Type::BigInteger.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "report_type",
          Helper::ExportHelper.report_type_to_s(report_type),
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
      assessment_id
    end

    def fetch_log_statistics
      sql = <<-SQL
              SELECT task_id, COUNT(*) AS num_rows, MIN(created_at) AS date_start, MAX(created_at) AS date_end, (MAX(created_at) - MIN(created_at)) AS execution_time, report_type
              FROM open_data_logs
              GROUP BY task_id, report_type
              ORDER BY MAX(created_at)
      SQL
      results = ActiveRecord::Base.connection.exec_query(sql)
      results.map { |result| result }
    end

    def fetch_latest_statistics
      sql = <<-SQL
              SELECT  task_id, COUNT(*) AS num_rows, MIN(created_at) AS date_start, MAX(created_at) AS date_end, (MAX(created_at) - MIN(created_at)) AS execution_time
              FROM open_data_logs
              WHERE task_id = (SELECT MAX(task_id) FROM open_data_logs)
              GROUP BY task_id
      SQL

      ActiveRecord::Base.connection.exec_query(sql).first
    end

    def fetch_latest_task_id
      sql = <<-SQL
              SELECT  task_id
              FROM open_data_logs
              WHERE task_id = (SELECT MAX(task_id) FROM open_data_logs)

      SQL

      ActiveRecord::Base.connection.exec_query(sql).first["task_id"]
    end

    def fetch_new_task_id(task_id = 0)
      return task_id if task_id.is_a?(Integer) && task_id != 0

      sql = <<-SQL
              SELECT MAX(task_id)
              FROM open_data_logs
      SQL
      task_id = ActiveRecord::Base.connection.exec_query(sql).first["max"]
      task_id.nil? ? 1 : task_id + 1
    end
  end
end
