module Gateway
  class SearchAddressGateway < StandardError
    def insert(object)
      insert_sql = <<-SQL
            INSERT INTO assessment_search_address(assessment_id, address)
            SELECT $1, $2
            WHERE NOT EXISTS(SELECT * FROM assessment_search_address WHERE assessment_id = $3)
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          object[:assessment_id],
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "address",
          object[:address],
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          object[:assessment_id],
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL", bindings)
    end
  end
end
