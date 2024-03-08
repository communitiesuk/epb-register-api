module Gateway
  class CountryGateway
    def fetch_countries
      sql = <<-SQL
          SELECT * FROM countries

      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL").map { |item| item.transform_keys(&:to_sym) }
    end
  end
end
