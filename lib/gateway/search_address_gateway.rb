module Gateway
  class SearchAddressGateway < StandardError

    def insert(object)
      insert_sql = <<-SQL
            INSERT INTO search_address(assessment_id, address)
            VALUES ($1, $2)
      SQL

      pp object

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          object[:assessment_id],
          ActiveRecord::Type::String.new,
          ),
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          object[:address],
          ActiveRecord::Type::String.new,
          ),
      ]

    ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
    end
  end
end
