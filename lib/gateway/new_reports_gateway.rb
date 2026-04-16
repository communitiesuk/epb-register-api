module Gateway
  class NewReportsGateway
    def fetch(start_date:, end_date:, current_page:, limit: 5000)
      sql = <<-SQL
      SELECT
      assessment_id
      FROM scotland.assessments
      WHERE created_at >= $1 AND created_at < $2
      ORDER BY created_at ASC
      LIMIT $3
      OFFSET $4;
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "limit",
          limit,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "offset",
          Helper::PaginationHelper.calculate_offset(current_page, limit),
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).map { |row| row["assessment_id"] }
    end

    def count(start_date:, end_date:)
      sql = <<-SQL
      SELECT
      COUNT(assessment_id)
      FROM scotland.assessments
      WHERE created_at >= $1 AND created_at < $2;
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first["count"]
    end

    def calculate_offset(current_page, limit)
      current_page = 1 if current_page <= 0
      (current_page - 1) * limit
    end
  end
end
