module Gateway
  class AddressSearchGateway
    ADDRESS_TYPES = {
      DOMESTIC: %w[SAP RdSAP],
      COMMERCIAL: %w[DEC DEC-RR CEPC CEPC-RR AC-REPORT AC-CERT],
    }.freeze

    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = Helper::ValidatePostcodeHelper.new.validate_postcode(postcode)

      ranking_sql = <<~SQL
        ,
        ((1 - TS_RANK_CD(
          TO_TSVECTOR('english', LOWER(CONCAT_WS(' ', address_line1, address_line2, address_line3))),
          TO_TSQUERY('english', LOWER($2))
        )) * 100) AS matched_rank,
        LEVENSHTEIN(
          LOWER($2),
          LOWER(CONCAT_WS(' ', address_line1, address_line2, address_line3)),
          0, 1, 1
        ) AS matched_difference
      SQL

      sql_assessments = <<~SQL
        SELECT aai.address_id,
               address_line1,
               address_line2,
               address_line3,
               address_line4,
               town,
               postcode,
               a.assessment_id,
               date_of_expiry,
               date_registered,
               cancelled_at,
               not_for_issue_at,
               type_of_assessment,
               linked_assessment_id
               #{ranking_sql if building_name_number}
        FROM assessments a
                 LEFT JOIN linked_assessments la ON a.assessment_id = la.assessment_id
                 INNER JOIN assessments_address_id aai on a.assessment_id = aai.assessment_id
        WHERE postcode = $1
      SQL

      if address_type
        list_of_types = ADDRESS_TYPES[address_type.to_sym].map { |n| "'#{n}'" }

        sql_assessments << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      end

      sql_assessments << " ORDER BY assessment_id "

      sql_address_base = <<~SQL
        SELECT CONCAT('UPRN-', LPAD(uprn, 12, '0')) AS address_id,
               address_line1,
               address_line2,
               address_line3,
               address_line4,
               town,
               postcode
               #{ranking_sql if building_name_number}
        FROM address_base
        WHERE postcode = $1
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "postcode",
          postcode.upcase,
          ActiveRecord::Type::String.new,
        ),
      ]

      if building_name_number
        binds <<
          ActiveRecord::Relation::QueryAttribute.new(
            "building_name_number",
            building_name_number.split(" ").join(" & "),
            ActiveRecord::Type::String.new,
          )
      end

      parse_results(
        [
          ActiveRecord::Base.connection.exec_query(
            sql_address_base,
            "SQL",
            binds,
          ),
          ActiveRecord::Base.connection.exec_query(
            sql_assessments,
            "SQL",
            binds,
          ),
        ].flatten,
      )
    end

    def search_by_address_id(address_id)
      stripped_id =
        if address_id.start_with?("RRN")
          address_id[4..-1]
        elsif address_id.start_with?("UPRN")
          address_id[5..-1].to_i.to_s
        end

      # Avoid using an OR in the WHERE clause to avoid serious performance issues
      sql_assessments = <<~SQL
         SELECT
          a.assessment_id,
          a.date_of_expiry,
          a.date_registered,
          a.cancelled_at,
          a.not_for_issue_at,
          a.address_line1,
          a.address_line2,
          a.address_line3,
          a.address_line4,
          a.town,
          a.postcode,
          aai.address_id,
          a.type_of_assessment
        FROM assessments a
        INNER JOIN assessments_address_id aai USING (assessment_id)
        WHERE a.assessment_id = $1
        UNION
        SELECT
          a.assessment_id,
          a.date_of_expiry,
          a.date_registered,
          a.cancelled_at,
          a.not_for_issue_at,
          a.address_line1,
          a.address_line2,
          a.address_line3,
          a.address_line4,
          a.town,
          a.postcode,
          aai.address_id,
          a.type_of_assessment
        FROM assessments a
        INNER JOIN assessments_address_id aai USING (assessment_id)
        WHERE aai.address_id = $2
        ORDER BY assessment_id
      SQL

      sql_address_base = <<~SQL
        SELECT CONCAT('UPRN-', LPAD(uprn, 12, '0')) AS address_id,
               address_line1,
               address_line2,
               address_line3,
               address_line4,
               town,
               postcode
        FROM address_base
        WHERE uprn = $1
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "stripped_address_id",
          stripped_id,
          ActiveRecord::Type::String.new,
        ),
      ]

      parse_results(
        [
          ActiveRecord::Base.connection.exec_query(
            sql_address_base,
            "SQL",
            binds,
          ),
          ActiveRecord::Base.connection.exec_query(
            sql_assessments,
            "SQL",
            binds + [
              ActiveRecord::Relation::QueryAttribute.new(
                "address_id",
                address_id,
                ActiveRecord::Type::String.new,
              ),
            ],
          ),
        ].flatten,
      )
    end

    def search_by_street_and_town(street, town, address_type)
      sql = <<~SQL
        SELECT aai.address_id,
               address_line1,
               address_line2,
               address_line3,
               address_line4,
               town,
               postcode,
               a.assessment_id,
               date_of_expiry,
               date_registered,
               cancelled_at,
               not_for_issue_at,
               type_of_assessment,
               linked_assessment_id
        FROM assessments a
               LEFT JOIN linked_assessments la ON a.assessment_id = la.assessment_id
               INNER JOIN assessments_address_id aai on a.assessment_id = aai.assessment_id
        WHERE (
              LOWER(town) LIKE $2
              OR
              LOWER(address_line2) LIKE $2
              OR
              LOWER(address_line3) LIKE $2
              OR
              LOWER(address_line4) LIKE $2
        )
        AND (
              LOWER(address_line1) LIKE $1
              OR
              LOWER(address_line2) LIKE $1
              OR
              LOWER(address_line3) LIKE $1
        )
      SQL

      if address_type
        list_of_types = ADDRESS_TYPES[address_type.to_sym].map { |n| "'#{n}'" }

        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      end

      sql << " ORDER BY assessment_id "

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "street",
          "%" + street.downcase + "%",
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "town",
          town.downcase,
          ActiveRecord::Type::String.new,
        ),
      ]

      parse_results(ActiveRecord::Base.connection.exec_query(sql, "SQL", binds))
    end

  private

    def parse_results(results)
      address_ids = {}
      address_hashes = {}
      remapped_addresses = []

      results
        .enum_for(:each_with_index)
        .each do |res, i|
          address_id = res["address_id"]

          if !res["linked_assessment_id"].nil? &&
              res["address_id"].start_with?("RRN-") &&
              res["linked_assessment_id"].to_s > res["address_id"].to_s
            address_id = "RRN-#{res['linked_assessment_id']}"
            results[i]["address_id"] = address_id
          end

          if res["address_id"].nil? || res["address_id"].start_with?("LPRN-")
            address_id =
              if res["linked_assessment_id"].to_s > res["assessment_id"].to_s
                "RRN-#{res['linked_assessment_id']}"
              else
                "RRN-#{res['assessment_id']}"
              end

            results[i]["address_id"] = address_id
          end

          address_ids[address_id] = [] unless address_ids.key? address_id
          address_ids[address_id].push i

          address_hash = compact_address(res).downcase.hash
          unless address_hashes.key? address_hash
            address_hashes[address_hash] = []
          end
          address_hashes[address_hash].push i
        end

      address_ids.each do |_, entries|
        root_entry = results[entries.first]
        entries_sharing_hash =
          address_hashes[compact_address(root_entry).downcase.hash]

        (entries_sharing_hash - entries).each do |result_to_update|
          next if remapped_addresses.include? result_to_update
          next if results[result_to_update]["address_id"].start_with? "UPRN"

          remapped_addresses.push result_to_update
          results[result_to_update]["address_id"] = root_entry["address_id"]
        end
      end

      address_ids = {}
      results
        .enum_for(:each_with_index)
        .each do |res, i|
          address_id = res["address_id"]
          address_ids[address_id] = [] unless address_ids.key? address_id
          address_ids[address_id].push i
        end

      addresses =
        address_ids.keys.map do |address_id|
          entries = address_ids[address_id]

          existing_assessments =
            entries.map do |entry|
              res = results[entry]
              next if res["assessment_id"].nil?

              status = update_expiry_and_status(res)

              next if %w[NOT_FOR_ISSUE CANCELLED].include? status

              {
                assessmentId: res["assessment_id"],
                assessmentStatus: status,
                assessmentType: res["type_of_assessment"],
              }
            end

          {
            address_id: address_id,
            address_line1: results[entries.first]["address_line1"],
            address_line2: results[entries.first]["address_line2"],
            address_line3: results[entries.first]["address_line3"],
            address_line4: results[entries.first]["address_line4"],
            town: results[entries.first]["town"],
            postcode: results[entries.first]["postcode"],
            existing_assessments: existing_assessments.compact,
            matched_rank: results[entries.first]["matched_rank"],
            matched_difference: results[entries.first]["matched_difference"],
          }.deep_stringify_keys
        end

      addresses.sort_by! do |address|
        [
          address["matched_rank"] || 0,
          address["matched_difference"] || 0,
          compact_address(address),
        ]
      end

      addresses.map { |address| record_to_address_domain(address) }
    end

    def record_to_address_domain(row)
      address_lines =
        [
          row["address_line1"],
          row["address_line2"],
          row["address_line3"],
          row["address_line4"],
        ].compact.reject { |a| a.to_s.strip.chomp.empty? }

      Domain::Address.new address_id: row["address_id"],
                          line1: address_lines[0],
                          line2: address_lines[1],
                          line3: address_lines[2],
                          line4: address_lines[3],
                          town: row["town"],
                          postcode: row["postcode"],
                          source:
                            if row["address_id"].include?("UPRN-")
                              "GAZETTEER"
                            else
                              "PREVIOUS_ASSESSMENT"
                            end,
                          existing_assessments: row["existing_assessments"]
    end

    def update_expiry_and_status(result)
      expiry_helper =
        Gateway::AssessmentExpiryHelper.new(
          result["cancelled_at"],
          result["not_for_issue_at"],
          result["date_of_expiry"],
        )
      expiry_helper.assessment_status
    end

    def compact_address(address)
      stringified = address.deep_stringify_keys

      [
        stringified["address_line1"],
        stringified["address_line2"],
        stringified["address_line3"],
        stringified["address_line4"],
        stringified["town"],
        stringified["postcode"],
      ].compact.reject { |a| a.to_s.strip.chomp.empty? }.join(" ")
    end
  end
end
