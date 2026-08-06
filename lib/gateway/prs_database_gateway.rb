# frozen_string_literal: true

module Gateway
  class PrsDatabaseGateway
    # Find the latest non-cancelled domestic certificate by UPRN
    # Do return opted out certificates
    # Do NOT return cancelled and not-for-issue
    # Do NOT return non-domestic
    def search_by_uprn(uprn)
      sql = <<~SQL.squish
        SELECT
          a.assessment_id AS epc_rrn,
          TO_CHAR(a.date_of_expiry, 'yyyy-mm-dd') AS expiry_date,
          a.address_line1 AS address_line1,
          a.address_line2 AS address_line2,
          a.address_line3 AS address_line3,
          a.address_line3 AS address_line4,
          a.town AS town,
          a.postcode AS postcode,
          a.current_energy_efficiency_rating AS current_energy_efficiency_rating,
          a.type_of_assessment AS type_of_assessment,
          a.assessment_id AS latest_epc_rrn_for_address
        FROM assessments a
        JOIN assessments_address_id ad
          ON a.assessment_id = ad.assessment_id
        WHERE ad.address_id = $1
          AND a.cancelled_at IS NULL
          AND a.not_for_issue_at IS NULL
          AND a.type_of_assessment IN ('RdSAP', 'SAP')
        ORDER BY
          a.date_of_expiry DESC,
          a.created_at DESC,
          a.date_of_assessment DESC,
          a.assessment_id DESC
        LIMIT 1
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "uprn",
          uprn,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", binds).first
    end

    # Find certificate by rrn number
    # Return the id of the latest non-cancelled domestic certificate at the same rrn address
    # Do return opted out certificates
    # Do return non-domestic, these will be raise a friendly error in the use-case
    # Do NOT return cancelled and not-for-issue
    def search_by_rrn(rrn)
      sql = <<~SQL.squish
        SELECT
          a.cancelled_at,
          a.not_for_issue_at,
          a.assessment_id AS epc_rrn,
          TO_CHAR(a.date_of_expiry, 'yyyy-mm-dd') AS expiry_date,
          a.address_line1 AS address_line1,
          a.address_line2 AS address_line2,
          a.address_line3 AS address_line3,
          a.address_line3 AS address_line4,
          a.town AS town,
          a.postcode AS postcode,
          a.current_energy_efficiency_rating AS current_energy_efficiency_rating,
          a.type_of_assessment AS type_of_assessment,
          (
            SELECT a1.assessment_id
            FROM assessments a1
            JOIN assessments_address_id aai1
              ON a1.assessment_id = aai1.assessment_id
            WHERE aai1.address_id = aai.address_id
              AND a1.type_of_assessment IN ('RdSAP', 'SAP')
              AND a1.cancelled_at IS NULL AND a.not_for_issue_at IS NULL
            ORDER BY
              a1.date_of_expiry DESC,
              a1.created_at DESC,
              a1.date_of_assessment DESC,
              a1.assessment_id DESC
            LIMIT 1
          ) AS latest_epc_rrn_for_address
        FROM assessments a
        JOIN assessments_address_id aai
          ON a.assessment_id = aai.assessment_id
        WHERE a.assessment_id = $1
          AND a.cancelled_at IS NULL
          AND a.not_for_issue_at IS NULL
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "rrn",
          rrn,
          ActiveRecord::Type::String.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", binds).first
    end
  end
end
