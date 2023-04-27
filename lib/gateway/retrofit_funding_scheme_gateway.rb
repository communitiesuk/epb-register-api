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

    def do_search(sql:, binds:)
      results = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      details_list = results.map { |result| row_to_domain(result) }.compact

      case details_list.count
      when 1
        details_list.first
      else
        nil
      end
    end

  private

    def row_to_domain(row)
      assessment_summary =
        UseCase::AssessmentSummary::Fetch.new.execute row["assessment_id"]

      return nil if block_given? && !yield(assessment_summary)

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
