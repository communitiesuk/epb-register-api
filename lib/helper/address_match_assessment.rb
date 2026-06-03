module Helper::AddressMatchAssessment
  def self.find_unmatched_assessments(is_scottish:, date_from:, date_to:, skip_existing: true)
    ActiveRecord::Base.logger = nil
    db = ActiveRecord::Base.connection
    db_schema = is_scottish ? "scotland" : "public"

    sql = <<-SQL
      SELECT a.assessment_id, a.address_line1, a.address_line2, a.address_line3, a.address_line4, a.postcode, a.town
      FROM #{db_schema}.assessments a
      JOIN #{db_schema}.assessments_address_id aai ON a.assessment_id = aai.assessment_id
    SQL

    if skip_existing == true
      sql.concat("WHERE aai.matched_uprn IS NULL")
    else
      skip_existing = false
    end

    if date_from && date_to
      sql.concat(" #{skip_existing ? 'AND' : 'WHERE'} date_registered BETWEEN '#{date_from}' AND '#{date_to}'")
    end
    db.exec_query sql
  end
end
