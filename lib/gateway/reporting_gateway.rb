module Gateway
  class ReportingGateway
    def assessments_by_region_and_type(start_date, end_date)
      sql = <<-SQL
        SELECT 
          COUNT(type_of_assessment) AS number_of_assessments, 
          type_of_assessment, 
          region 
        FROM assessments a 
        LEFT JOIN 
          postcode_geolocation b 
        ON(a.postcode = b.postcode) 
        WHERE
          date_registered BETWEEN $1 AND $2
        GROUP BY type_of_assessment, region
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date - 1,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date + 1,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end
  end
end
