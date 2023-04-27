module Gateway
  class RetrofitFundingSchemeGateway
    def fetch_by_uprn(uprn)
      sql = <<-SQL
      SELECT a.assessment_id
      FROM assessments AS a
      WHERE a.assessment_id IN (
        SELECT aai.assessment_id
        FROM assessments_address_id AS aai
        WHERE aai.address_id = CONCAT('UPRN-', $1::text))
      AND a.type_of_assessment IN ('SAP', 'RdSAP')
      AND a.opt_out = false
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
      result.nil? ? nil : id_to_domain(result["assessment_id"])
    end

    def id_to_domain(assessment_id)
      assessment_summary =
        UseCase::AssessmentSummary::Fetch.new.execute assessment_id

      Domain::AssessmentRetrofitFundingDetails.new(
        address: assessment_summary[:address].slice(
          :address_line1,
          :address_line2,
          :address_line3,
          :address_line4,
          :town,
          :postcode,
        ).transform_values { |v| v || "" },
        lodgement_date: assessment_summary[:date_registered],
        uprn: assessment_summary[:address_id],
        current_energy_efficiency_rating: assessment_summary[:current_energy_efficiency_rating],
      )
    rescue UseCase::AssessmentSummary::Fetch::AssessmentUnavailable
      nil
    end
  end
end
