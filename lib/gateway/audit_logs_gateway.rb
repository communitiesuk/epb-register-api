module Gateway
  class AuditLogsGateway
    def add_audit_event(event_type:, entity_id:, entity_type:, data: nil)
      insert_sql = <<-SQL
            INSERT INTO audit_logs(event_type, entity_id, entity_type, data)
            VALUES ($1, $2, $3, $4)
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "event_type",
          event_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "entity_id",
          entity_id,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "entity_type",
          entity_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "data",
          data,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
    end
  end
end
