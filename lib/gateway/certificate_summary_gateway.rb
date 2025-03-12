module Gateway
  class CertificateSummaryGateway
    def fetch(assessment_id)
      sql = <<-SQL
      SELECT
      a.created_at,
      a.opt_out,
      a.cancelled_at,
      a.not_for_issue_at,
      aai.address_id AS assessment_address_id,
      ac.country_id,
      a.scheme_assessor_id,
      ass.first_name AS assessor_first_name,
      ass.last_name AS assessor_last_name,
      ass.telephone_number AS assessor_telephone_number,
      ass.email AS assessor_email,
      ass.registered_by AS scheme_id,
      s.name AS scheme_name,
      x.schema_type,
      x.xml,
      gda.green_deal_plan_id,
      (SELECT count(*)
       FROM assessments_address_id
       WHERE address_id =
             (SELECT address_id from assessments_address_id where assessment_id = $1)) AS matching_assessment_address_id
      FROM assessments a
      LEFT OUTER JOIN green_deal_assessments gda ON a.assessment_id = gda.assessment_id
      INNER JOIN assessors ass ON a.scheme_assessor_id = ass.scheme_assessor_id
      INNER JOIN schemes s ON ass.registered_by = s.scheme_id
      INNER JOIN assessments_xml x ON a.assessment_id = x.assessment_id
      INNER JOIN assessments_address_id aai ON a.assessment_id = aai.assessment_id
      LEFT JOIN assessments_country_ids ac ON a.assessment_id = ac.assessment_id
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
