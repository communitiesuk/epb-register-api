module Gateway
  class OpenDataLogGateway
    def insert(assessment_id, task_id)
      insert_sql = <<-SQL
            INSERT INTO open_data_logs(assessment_id, assessment_hash_id, created_at, task_id)
            VALUES ($1, $2, $3, $4)
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_hash",
          "",
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
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
      assessment_id
    end
  end
end
