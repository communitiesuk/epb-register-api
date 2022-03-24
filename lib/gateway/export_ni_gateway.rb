module Gateway
  class ExportNiGateway
    def fetch_assessments(type_of_assessment:, date_from: "1990-01-01", date_to: Time.now)
      sql = <<-SQL
      SELECT
      a.assessment_id,
      a.date_registered as lodgement_date,
      a.created_at as lodgement_datetime,
      CASE WHEN UPPER(aa.address_id) NOT LIKE 'UPRN-%' THEN null ELSE
      aa.address_id END as uprn,
     CASE WHEN opt_out IS NULL THEN false else opt_out end as opt_out,
        CASE WHEN cancelled_at IS NOT NULL OR not_for_issue_at IS NOT NULL THEN true ELSE false end as cancelled
      FROM assessments a
      INNER JOIN assessments_xml ax USING(assessment_id)
      LEFT JOIN assessments_address_id aa USING(assessment_id)
      WHERE a.date_registered BETWEEN $1 AND $2 AND (a.postcode LIKE 'BT%' )
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "date_from",
          date_from,
          ActiveRecord::Type::Date.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "date_to",
          date_to,
          ActiveRecord::Type::Date.new,
        ),
      ]

      # TOD0 extract this to helper method
      if type_of_assessment.is_a?(Array)
        valid_type = %w[RdSAP SAP CEPC CEPC-RR]
        invalid_types = type_of_assessment - valid_type
        raise StandardError, "Invalid types" unless invalid_types.empty?
      end
      list_of_types = type_of_assessment.map { |n| "'#{n}'" }
      sql << <<~SQL_TYPE_OF_ASSESSMENT
        AND type_of_assessment IN(#{list_of_types.join(',')})
      SQL_TYPE_OF_ASSESSMENT

      domestic_assessment_types = ["RdSAP SAP"]

      if type_of_assessment.any? { |x| domestic_assessment_types.include?(x) }
        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND ax.schema_type LIKE '%NI%'
        SQL_TYPE_OF_ASSESSMENT
      end

      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings)

      results.map { |result| result }
    end
  end
end
