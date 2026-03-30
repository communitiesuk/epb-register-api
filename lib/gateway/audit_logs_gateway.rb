module Gateway
  class AuditLogsGateway
    def add_audit_event(audit_domain_object)
      insert_sql = <<-SQL
            INSERT INTO audit_logs(event_type, entity_id, entity_type, data)
            VALUES ($1, $2, $3, $4)
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "event_type",
          audit_domain_object.event_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "entity_id",
          audit_domain_object.entity_id,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "entity_type",
          audit_domain_object.entity_type,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "data",
          audit_domain_object.data,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
    end

    def fetch_assessment_ids(event_type:, start_date:, end_date: Time.now)
      sql = <<-SQL
            SELECT entity_id
            FROM audit_logs
            WHERE 0=0
            AND timestamp BETWEEN $1 AND $2
            AND event_type = $3
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          start_date,
          ActiveRecord::Type::Date.new,
        ),

        ActiveRecord::Relation::QueryAttribute.new(
          "date_to",
          end_date,
          ActiveRecord::Type::Date.new,
        ),

        ActiveRecord::Relation::QueryAttribute.new(
          "event_type",
          event_type,
          ActiveRecord::Type::String.new,
        ),

      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).map { |result| result["entity_id"] }
    end

    def fetch_scottish_events(event_types:, start_date:, end_date:, current_page:, limit: 5000)
      sql = <<-SQL
            SELECT entity_id, event_type, timestamp
      SQL

      sql << shared_scottish_event_sql(event_types:)

      sql << <<~SQL
        ORDER BY timestamp ASC
        LIMIT $3
        OFFSET $4;
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          start_date,
          ActiveRecord::Type::Date.new,
        ),

        ActiveRecord::Relation::QueryAttribute.new(
          "date_to",
          end_date,
          ActiveRecord::Type::Date.new,
        ),

        ActiveRecord::Relation::QueryAttribute.new(
          "limit",
          limit,
          ActiveRecord::Type::Integer.new,
        ),

        ActiveRecord::Relation::QueryAttribute.new(
          "offset",
          calculate_offset(current_page, limit),
          ActiveRecord::Type::String.new,
        ),

      ]

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)

      results.map { |result| Domain::AssessmentStatusEvent.new(assessment_event: result.symbolize_keys).to_hash }
    end

    def count_scottish_events(event_types:, start_date:, end_date:)
      sql = <<-SQL
            SELECT COUNT(*)
      SQL

      sql << shared_scottish_event_sql(event_types:)

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          start_date,
          ActiveRecord::Type::Date.new,
        ),

        ActiveRecord::Relation::QueryAttribute.new(
          "date_to",
          end_date,
          ActiveRecord::Type::Date.new,
        ),

      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first["count"]
    end

  private

    def calculate_offset(current_page, limit)
      current_page = 1 if current_page <= 0
      (current_page - 1) * limit
    end

    def shared_scottish_event_sql(event_types:)
      sql = <<-SQL
            FROM audit_logs
            WHERE timestamp BETWEEN $1 AND $2
            AND entity_type = 'scottish_assessment'
      SQL

      valid_scottish_events = %w[
        scottish_lodgement
        scottish_opt_out
        scottish_opt_in
        scottish_cancelled
        scottish_address_id_updated
      ]

      if event_types.is_a?(Array)
        invalid_types = event_types - valid_scottish_events
        raise StandardError, "Invalid types" unless invalid_types.empty?

        events = "(#{event_types.map { |n| "'#{n}'" }.join(',')})"
        sql << <<~SQL
          AND event_type IN #{events}
        SQL
      else
        unless valid_scottish_events.include? event_type
          raise StandardError, "Invalid types"
        end

        sql << <<~SQL
          AND event_type = '#{event_type}'
        SQL
      end

      sql
    end
  end
end
