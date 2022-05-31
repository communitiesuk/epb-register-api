module Gateway
  class HomeEnergyRetrofitAdviceGateway
    def fetch_by_rrn(rrn)
      sql = <<-SQL
        SELECT
          xml,
          schema_type
        FROM assessments_xml ass_xml
          JOIN assessments ass ON ass.assessment_id = ass_xml.assessment_id
        WHERE ass_xml.assessment_id = $1
        AND ass.cancelled_at IS NULL
        AND ass.not_for_issue_at IS NULL
        AND ass.postcode NOT LIKE 'BT%'
        AND ass.type_of_assessment IN ('SAP', 'RdSAP')
      SQL

      binds = [
        string_attribute("rrn", rrn),
      ]

      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      result.first
    end

  private

    def string_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
      )
    end
  end
end
