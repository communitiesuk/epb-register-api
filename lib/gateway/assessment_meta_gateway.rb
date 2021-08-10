module Gateway
  class AssessmentMetaGateway
    class Assessment < ActiveRecord::Base
    end

    def fetch(assessment_id)
      sql = <<-SQL
      SELECT
      a.assessment_id,
      a.type_of_assessment,
      a.opt_out,
      a.created_at,
      a.cancelled_at,
      a.not_for_issue_at,
      x.schema_type,
      a.address_id
      FROM assessments a
      INNER JOIN assessments_xml x on a.assessment_id = x.assessment_id
      WHERE a.assessment_id = $1
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first
    end
  end
end