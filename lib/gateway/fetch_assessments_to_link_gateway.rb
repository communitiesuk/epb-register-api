# frozen_string_literal: true

module Gateway
  class FetchAssessmentsToLinkGateway
    class TempLinkingTable < ActiveRecord::Base
    end

    FETCH_ASSESSMENTS_SQL = <<-SQL
        WITH addresses_we_want AS (
        WITH grouped_addresses AS (
        SELECT REGEXP_REPLACE(address, '(?<=[^[:digit:]])[[:punct:]](?=[^[:digit:]])|(?<=[[:digit:]])[[:punct:]](?=[^[:digit:]])|''', '', 'g') AS address, postcode, COUNT(*) AS ct, COUNT(DISTINCT(aaid.address_id)) AS cid
        FROM (assessments a LEFT JOIN assessment_search_address asa ON a.assessment_id = asa.assessment_id)
        LEFT JOIN assessments_address_id aaid ON (a.assessment_id = aaid.assessment_id AND asa.assessment_id = aaid.assessment_id)
        WHERE a.type_of_assessment IN ('CEPC', 'CEPC-RR', 'AC-CERT', 'AC-REPORT', 'DEC', 'DEC-RR')
        AND a.cancelled_at IS NULL
        AND a.not_for_issue_at IS NULL
        GROUP BY REGEXP_REPLACE(address, '(?<=[^[:digit:]])[[:punct:]](?=[^[:digit:]])|(?<=[[:digit:]])[[:punct:]](?=[^[:digit:]])|''', '', 'g'), postcode)
        SELECT address, postcode
        FROM grouped_addresses
        WHERE ct > 1 AND cid >1),
        non_domestic_certs AS (
                           SELECT a.assessment_id,
                                  REGEXP_REPLACE(asa.address, '(?<=[^[:digit:]])[[:punct:]](?=[^[:digit:]])|(?<=[[:digit:]])[[:punct:]](?=[^[:digit:]])|''', '', 'g') AS address,
                                  a.postcode,
                                  aaid.address_id,
                                  aaid.source
                            FROM assessments a
                                     JOIN assessments_address_id aaid ON a.assessment_id = aaid.assessment_id
                                     JOIN assessment_search_address asa ON a.assessment_id = asa.assessment_id
                            WHERE a.type_of_assessment IN ('CEPC', 'CEPC-RR', 'AC-CERT', 'AC-REPORT', 'DEC', 'DEC-RR')
                            AND a.cancelled_at IS NULL
                            AND a.not_for_issue_at IS NULL
                           )
        SELECT aww.address, aww.postcode, assessment_id, address_id, source, dense_rank() over (ORDER BY aww.address, aww.postcode) group_id
        FROM addresses_we_want aww LEFT JOIN non_domestic_certs ndc ON (aww.address = ndc.address AND aww.postcode = ndc.postcode)
    SQL
    def create_and_populate_temp_table
      sql = <<-SQL
        SELECT * INTO temp_linking_tables FROM (#{FETCH_ASSESSMENTS_SQL}) AS temp
      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL")
    end

    def fetch_groups_to_skip
      sql = <<~SQL
        (SELECT DISTINCT group_id
        FROM (
            WITH unique_address_id_groups AS (
                SELECT DISTINCT address_id, group_id
                FROM temp_linking_tables
                )
            SELECT group_id, COUNT(address_id) over (partition BY address_id)
            FROM unique_address_id_groups
            GROUP BY address_id, group_id
            ) AS table_dupes
        WHERE count > 1
        ORDER BY group_id ASC)
        UNION
        SELECT group_id from
        (WITH unique_source_groups AS (
        SELECT DISTINCT group_id, source
        FROM temp_linking_tables)
        SELECT group_id, source, COUNT(unique_source_groups.source) over (partition BY group_id)
        FROM unique_source_groups
        GROUP BY group_id, unique_source_groups.source) as id_sources
        WHERE count = 1
        AND source = 'epb_team_update'
      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL").map { |rows| rows["group_id"] }
    end

    def fetch_assessments_by_group_id(group_id)
      sql = <<-SQL
        WITH uniq_address_ids AS (
        SELECT DISTINCT(address_id) AS address_id
        FROM temp_linking_tables
        WHERE group_id = $1 )
        SELECT a.assessment_id, aai.address_id, a.date_registered, aai.source
        FROM assessments a
        JOIN assessments_address_id aai ON a.assessment_id = aai.assessment_id
        JOIN uniq_address_ids uai ON uai.address_id = aai.address_id
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "group_id",
          group_id,
          ActiveRecord::Type::String.new,
        ),
      ]
      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds).to_a
      if result.empty?
        raise Boundary::NoData, "bulk linking assessment group_id: #{group_id}"
      else
        Domain::AssessmentsToLink.new(data: result)
      end
    end

    def get_max_group_id
      TempLinkingTable.maximum(:group_id)
    end

    def drop_temp_table
      sql = <<-SQL
        DROP TABLE IF EXISTS temp_linking_tables
      SQL

      ActiveRecord::Base.connection.exec_query(sql, "SQL")
    end
  end
end
