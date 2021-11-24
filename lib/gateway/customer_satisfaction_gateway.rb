module Gateway
  class CustomerSatisfactionGateway
    def upsert(customer_satisfaction)
      sql = <<-SQL
       INSERT INTO customer_satisfaction(month, very_satisfied, satisfied, neither,dissatisfied,very_dissatisfied )
       VALUES($1, $2, $3, $4, $5, $6)
        ON CONFLICT(month)
        DO UPDATE SET very_satisfied = $2, satisfied= $3, neither=$4, dissatisfied=$5, very_dissatisfied= $6
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "month",
          customer_satisfaction.stats_date,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "very_satisfied",
          customer_satisfaction.very_satisfied,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "satisfied",
          customer_satisfaction.satisfied,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "neither",
          customer_satisfaction.neither,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "dissatisfied",
          customer_satisfaction.dissatisfied,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "very_dissatisfied",
          customer_satisfaction.very_dissatisfied,
          ActiveRecord::Type::Integer.new,
        ),

      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end

    def fetch
      sql = <<-SQL
         SELECT to_char(month, 'YYYY-MM') as month, very_satisfied, satisfied, neither, dissatisfied, very_dissatisfied
          FROM customer_satisfaction
          ORDER BY month
      SQL

      ActiveRecord::Base.connection.exec_query(sql)
    end
  end
end
