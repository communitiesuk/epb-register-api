module Gateway
  class SearchAddressGateway < StandardError
    def insert(object, is_scottish = false)
      schema = is_scottish ? "scotland." : "public."
      insert_sql = <<-SQL
            INSERT INTO #{schema}assessment_search_address(assessment_id, address)
            SELECT $1, $2
            WHERE NOT EXISTS(SELECT * FROM #{schema}assessment_search_address WHERE assessment_id = $3)
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

    def bulk_insert
      insert_sql = <<-SQL
            INSERT INTO assessment_search_address(assessment_id, address)
            SELECT assessment_id, trim(lower(CONCAT(address_line1,
                CASE WHEN address_line2 IS NULL OR address_line2='' THEN '' ELSE ' ' END,
                address_line2,
                CASE WHEN address_line3 IS NULL OR address_line3='' THEN '' ELSE ' ' END,
                address_line3,
                CASE WHEN address_line4 IS NULL OR address_line4='' THEN '' ELSE ' ' END,
                address_line4))) FROM assessments a
            WHERE NOT EXISTS(SELECT * FROM assessment_search_address WHERE assessment_id = a.assessment_id)
      SQL

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL")
    end
  end
end
