module Gateway
  class RetrofitFundingSchemeGateway
    def find_by_uprn(uprn)
      sql = <<-SQL
      SELECT a.assessment_id
      FROM assessments AS a
      WHERE a.assessment_id IN (
        SELECT aai.assessment_id
        FROM assessments_address_id AS aai
        WHERE aai.address_id = CONCAT('UPRN-', $1::text))
      AND a.type_of_assessment IN ('SAP', 'RdSAP')
      AND a.opt_out = FALSE
      AND a.cancelled_at IS NULL
      AND a.not_for_issue_at IS NULL
      ORDER BY date_registered DESC
      LIMIT 1
      SQL

      do_search(
        sql:,
        binds: [
          Helper::AddressSearchHelper.string_attribute("uprn", uprn),
        ],
      )
    end

  private

    def do_search(sql:, binds:)
      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds).first
      result.nil? ? nil : result["assessment_id"]
    end
  end
end
