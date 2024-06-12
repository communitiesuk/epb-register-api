# frozen_string_literal: true

module Gateway
  class FetchAssessmentsToLinkGateway
    class TempLinkingTable < ActiveRecord::Base
    end

    FETCH_ASSESSMENTS_SQL = <<-SQL
        WITH addresses_we_want AS (
        WITH grouped_addresses AS (
        SELECT regexp_replace(address, '[[:punct:]]', '', 'g') as address, postcode, count(*) as ct, count (DISTINCT(aaid.address_id)) as cid
        FROM (assessments a LEFT JOIN assessment_search_address asa ON a.assessment_id = asa.assessment_id)
        LEFT JOIN assessments_address_id aaid ON (a.assessment_id = aaid.assessment_id AND asa.assessment_id = aaid.assessment_id)
        WHERE a.type_of_assessment IN ('CEPC', 'CEPC-RR', 'AC-CERT', 'AC-REPORT', 'DEC', 'DEC-RR')
        AND a.cancelled_at IS NULL
        AND a.not_for_issue_at IS NULL
        GROUP BY regexp_replace(address, '[[:punct:]]', '', 'g'), postcode)
        SELECT address, postcode
        FROM grouped_addresses
        WHERE ct > 1 AND cid >1),
        non_domestic_certs AS (SELECT a.assessment_id,
                                  regexp_replace(asa.address, '[[:punct:]]', '', 'g') as address,
                                  a.date_registered,
                                  a.postcode,
                                  aaid.address_id
                            FROM assessments a
                                     JOIN assessments_address_id aaid ON a.assessment_id = aaid.assessment_id
                                     JOIN assessment_search_address asa ON a.assessment_id = asa.assessment_id
                            WHERE a.type_of_assessment IN ('CEPC', 'CEPC-RR', 'AC-CERT', 'AC-REPORT', 'DEC', 'DEC-RR')
                            AND a.cancelled_at IS NULL
                            AND a.not_for_issue_at IS NULL)
        SELECT aww.address, aww.postcode, assessment_id, address_id, date_registered, dense_rank() over (order by aww.address, aww.postcode) group_id
        FROM addresses_we_want aww LEFT JOIN non_domestic_certs ndc ON (aww.address = ndc.address AND aww.postcode = ndc.postcode)
    SQL

    def create_and_populate_temp_table
      insert_sql = <<-SQL
        SELECT * INTO temp_linking_tables FROM (#{FETCH_ASSESSMENTS_SQL}) AS temp
      SQL

      ActiveRecord::Base.connection.exec_query(insert_sql, "SQL")
    end
  end
end
