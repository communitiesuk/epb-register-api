module Gateway
  class UserSatisfactionGateway
    def upsert(satisfaction_object)
      sql = <<-SQL
       INSERT INTO user_satisfaction(month, very_satisfied, satisfied, neither,dissatisfied,very_dissatisfied )
       VALUES($1, $2, $3, $4, $5, $6)
        ON CONFLICT(month)
        DO UPDATE SET very_satisfied = $2, satisfied= $3, neither=$4, dissatisfied=$5, very_dissatisfied= $6
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "month",
          satisfaction_object.stats_date,
          ActiveRecord::Type::DateTime.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "very_satisfied",
          satisfaction_object.very_satisfied,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "satisfied",
          satisfaction_object.satisfied,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "neither",
          satisfaction_object.neither,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "dissatisfied",
          satisfaction_object.dissatisfied,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "very_dissatisfied",
          satisfaction_object.very_dissatisfied,
          ActiveRecord::Type::Integer.new,
        ),

      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)
    end

    def fetch
      sql = <<-SQL
         SELECT to_char(month, 'YYYY-MM') as month, very_satisfied, satisfied, neither, dissatisfied, very_dissatisfied
          FROM user_satisfaction
          ORDER BY month DESC
      SQL

      ActiveRecord::Base.connection.exec_query(sql)
    end
  end
end
