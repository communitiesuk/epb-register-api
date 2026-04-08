module Gateway
  class AssessmentMetaGateway
    class Assessment < ActiveRecord::Base
    end

    def fetch(assessment_id, is_scottish: false)
      schema = Helper::ScotlandHelper.select_schema(is_scottish)

      sql = <<-SQL
      SELECT
      a.type_of_assessment,
      a.opt_out,
      a.hashed_assessment_id,
      a.created_at,
      a.cancelled_at,
      a.not_for_issue_at,
      a.date_of_expiry,
      x.schema_type,
      aai.address_id AS assessment_address_id,
      ac.country_id,
      CASE WHEN EXISTS(SELECT * FROM #{schema}green_deal_assessments g WHERE g.assessment_id = a.assessment_id) THEN true ELSE false END as green_deal
      FROM #{schema}assessments a
      INNER JOIN #{schema}assessments_xml x ON a.assessment_id = x.assessment_id
      INNER JOIN #{schema}assessments_address_id aai ON a.assessment_id = aai.assessment_id
      LEFT JOIN #{schema}assessments_country_ids ac ON a.assessment_id = ac.assessment_id

      WHERE a.assessment_id = $1
      SQL

      bindings = [
        ActiveRecord::Relation::QueryAttribute.new(
          "assessment_id",
          assessment_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first

      if is_scottish
        result.nil? ? nil : Domain::ScottishAssessmentMetaData.new(meta_data: result.symbolize_keys).to_hash
      else
        result
      end
    end
  end
end
