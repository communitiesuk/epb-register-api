module Gateway
  class AddressSearchGateway
    include ReadOnlyDatabaseAccess
    def initialize
      @allow_scottish = Helper::Toggles.enabled?("register-api-allow-scottish-address-search")
    end

    ADDRESS_TYPES = {
      DOMESTIC: %w[SAP RdSAP],
      COMMERCIAL: %w[DEC DEC-RR CEPC CEPC-RR AC-REPORT AC-CERT CS63 DEC-AR],
    }.freeze

    def search_by_postcode(postcode, building_name_number, address_type)
      postcode = Helper::ValidatePostcodeHelper.format_postcode(postcode)

      ranking_sql = build_ranking_sql(building_name_number)
      type_filter = build_type_filter(address_type)

      sql_assessments = build_assessments_sql(ranking_sql, type_filter)
      scottish_sql_assessments = build_assessments_sql(ranking_sql, type_filter, schema: "scotland") if @allow_scottish
      binds = build_binds(postcode, building_name_number)

      sql_address_base = build_address_base_sql(ranking_sql)

      queries = [
        [:address_base, sql_address_base],
        [:assessments, sql_assessments],
      ]

      queries << [:scotland, scottish_sql_assessments] if @allow_scottish

      read_only do
        parse_results(
          queries.flat_map do |type, sql|
            result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)

            type == :address_base ? result.map { |address| title_case_address(address) } : result.to_a
          end,
        )
      end
    end

    def search_by_address_id(address_id)
      stripped_id =
        if address_id.start_with?("RRN")
          address_id[4..]
        elsif address_id.start_with?("UPRN")
          address_id[5..].to_i.to_s
        end

      sql_assessments = build_address_id_assessments_sql
      scottish_sql_assessments = build_address_id_assessments_sql(schema: "scotland")

      sql_address_base = build_address_base_sql_for_address_id

      address_base_binds = [
        query_attribute("stripped_address_id", stripped_id),
      ]

      assessment_binds = address_base_binds + [
        query_attribute("address_id", address_id),
      ]

      queries = [
        [
          :address_base,
          sql_address_base,
          address_base_binds,
        ],
        [
          :assessments,
          sql_assessments,
          assessment_binds,
        ],
      ]

      if @allow_scottish
        queries << [
          :scottish_assessments,
          scottish_sql_assessments,
          assessment_binds,
        ]
      end

      read_only do
        results =
          queries.flat_map do |type, sql, binds|
            result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)

            if type == :address_base
              result.map { |address| title_case_address(address) }
            else
              result.to_a
            end
          end

        if @allow_scottish
          parse_address_id_results(results)
        else
          parse_results(results)
        end
      end
    end

    def search_by_street_and_town(street, town, address_type)
      ranking_sql = build_ranking_sql(town)
      type_filter = build_type_filter(address_type)
      binds = build_street_and_town_binds(street, town)

      sql_assessments = build_street_and_town_assessments_sql(ranking_sql, type_filter)
      scottish_sql_assessments = build_street_and_town_assessments_sql(ranking_sql, type_filter, schema: "scotland")

      sql_address_base = build_street_and_town_address_base_sql(ranking_sql)

      queries = [
        [:address_base, sql_address_base],
        [:assessments, sql_assessments],
      ]

      queries << [:scotland, scottish_sql_assessments] if @allow_scottish

      read_only do
        parse_results(
          queries.flat_map do |type, sql|
            result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)

            type == :address_base ? result.map { |address| title_case_address(address) } : result.to_a
          end,
        )
      end
    end

  private

    def build_address_base_sql(ranking_sql)
      <<~SQL
        #{base_select_sql}
        #{ranking_sql}
        FROM address_base
        WHERE postcode = $1
        #{exclude_scotland_clause}
      SQL
    end

    def base_select_sql
      <<~SQL
        SELECT CONCAT('UPRN-', LPAD(uprn, 12, '0')) AS address_id,
           address_line1,
           address_line2,
           address_line3,
           address_line4,
           town,
           postcode,
           country_code
      SQL
    end

    def exclude_scotland_clause
      return "" if @allow_scottish

      "AND LOWER(country_code) IS DISTINCT FROM LOWER('S')"
    end

    def build_address_base_sql_for_address_id
      <<~SQL
        #{base_select_sql}
        FROM address_base
        WHERE uprn = $1
        #{exclude_scotland_clause}
      SQL
    end

    def build_street_and_town_address_base_sql(ranking_sql)
      <<~SQL
        #{base_select_sql}
        #{ranking_sql}
        FROM address_base
        WHERE (
              LOWER(town) LIKE $2
              OR LOWER(address_line2) LIKE $2
        )
        AND (
              LOWER(address_line1) LIKE $1
              OR LOWER(address_line2) LIKE $1
        )
        #{exclude_scotland_clause}
      SQL
    end

    def query_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
      )
    end

    # methods for search_by_postcode
    # -----
    def build_ranking_sql(search_term)
      return "" unless search_term

      text_search_method = [" ", "&", "'"].any? { |char| search_term.include?(char) } ? "PLAINTO_TSQUERY" : "TO_TSQUERY"

      <<~SQL
        ,
        ((1 - TS_RANK_CD(
          TO_TSVECTOR('english', LOWER(CONCAT_WS(' ', address_line1, address_line2, address_line3))),
          #{text_search_method}('english', LOWER($2))
        )) * 100) AS matched_rank,
        LEVENSHTEIN(
          LOWER($2),
          LOWER(CONCAT_WS(' ', address_line1, address_line2, address_line3)),
          0, 1, 1
        ) AS matched_difference
      SQL
    end

    def build_type_filter(address_type)
      return "" unless address_type

      types = ADDRESS_TYPES[address_type.to_sym]
      return "" unless types

      list_of_types = types.map { |n| "'#{n}'" }
      <<~SQL
        AND type_of_assessment IN(#{list_of_types.join(',')})
      SQL
    end

    def build_assessments_sql(ranking_sql, type_filter, schema: nil)
      prefix = schema ? "#{schema}." : ""

      <<~SQL
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
               #{ranking_sql}
        FROM #{prefix}assessments a
                 LEFT JOIN #{prefix}linked_assessments la ON a.assessment_id = la.assessment_id
                 INNER JOIN #{prefix}assessments_address_id aai ON a.assessment_id = aai.assessment_id
        WHERE postcode = $1
        AND cancelled_at IS NULL
        AND not_for_issue_at IS NULL
        #{type_filter}
        ORDER BY assessment_id
      SQL
    end

    def build_binds(postcode, building_name_number)
      binds = [
        query_attribute("postcode", postcode.upcase),
      ]

      if building_name_number
        binds << query_attribute("building_name_number", building_name_number.split.join(" & "))
      end

      binds
    end

    def build_address_id_assessments_sql(schema: nil)
      prefix = schema ? "#{schema}." : ""
      schema_name = schema || "public"

      # Avoid using an OR in the WHERE clause to avoid serious performance issues
      <<~SQL
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
          a.type_of_assessment,
          '#{schema_name}' AS schema_name
        FROM #{prefix}assessments a
        INNER JOIN #{prefix}assessments_address_id aai USING (assessment_id)
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
          a.type_of_assessment,
          '#{schema_name}' AS schema_name
        FROM #{prefix}assessments a
        INNER JOIN #{prefix}assessments_address_id aai USING (assessment_id)
        WHERE aai.address_id = $2
        ORDER BY assessment_id
      SQL
    end

    # ---------------------------------------------
    def build_street_and_town_binds(street, town)
      [
        query_attribute("street", "%#{street.downcase}%"),
        query_attribute("town", town.downcase),
      ]
    end

    def build_street_and_town_assessments_sql(ranking_sql, type_filter, schema: nil)
      prefix = schema ? "#{schema}." : ""

      <<~SQL
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
                 #{ranking_sql}
          FROM #{prefix}assessments a
                 LEFT JOIN #{prefix}linked_assessments la ON a.assessment_id = la.assessment_id
                 INNER JOIN #{prefix}assessments_address_id aai ON a.assessment_id = aai.assessment_id
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
        #{type_filter}
        ORDER BY assessment_id
      SQL
    end

    # ---------------------------------------------
    def parse_address_id_results(results)
      address_ids = {}
      address_hashes = {}
      remapped_addresses = []

      results
        .enum_for(:each_with_index)
        .each do |res, i|
        res["address_id"]

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

        address_key = address_group_key(res)

        address_ids[address_key] = [] unless address_ids.key?(address_key)
        address_ids[address_key].push i

        address_hash = compact_address(res).downcase.hash

        unless address_hashes.key? address_hash
          address_hashes[address_hash] = []
        end
        address_hashes[address_hash].push i
      end

      address_ids.each_value do |entries|
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
        address_key = address_group_key(res)
        address_ids[address_key] = [] unless address_ids.key?(address_key)
        address_ids[address_key].push i
      end

      statuses_to_exclude = %w[NOT_FOR_ISSUE CANCELLED]

      addresses =
        address_ids.keys.map do |address_key|
          entries = address_ids[address_key]
          address_id = results[entries.first]["address_id"]

          existing_assessments =
            entries.map do |entry|
              res = results[entry]
              next if res["assessment_id"].nil?

              status = update_expiry_and_status(res)

              next if statuses_to_exclude.include? status

              {
                assessmentId: res["assessment_id"],
                assessmentStatus: status,
                assessmentType: res["type_of_assessment"],
              }
            end

          {
            address_id:,
            address_line1: results[entries.first]["address_line1"],
            address_line2: results[entries.first]["address_line2"],
            address_line3: results[entries.first]["address_line3"],
            address_line4: results[entries.first]["address_line4"],
            town: results[entries.first]["town"],
            postcode: results[entries.first]["postcode"],
            country_code: results[entries.first]["country_code"],
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

    def address_group_key(res)
      schema_name = res["schema_name"] || res["schema"] || "public"
      [schema_name, res["address_id"]]
    end

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

      address_ids.each_value do |entries|
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

      statuses_to_exclude = %w[NOT_FOR_ISSUE CANCELLED]

      addresses =
        address_ids.keys.map do |address_id|
          entries = address_ids[address_id]

          existing_assessments =
            entries.map do |entry|
              res = results[entry]
              next if res["assessment_id"].nil?

              status = update_expiry_and_status(res)

              next if statuses_to_exclude.include? status

              {
                assessmentId: res["assessment_id"],
                assessmentStatus: status,
                assessmentType: res["type_of_assessment"],
              }
            end

          {
            address_id:,
            address_line1: results[entries.first]["address_line1"],
            address_line2: results[entries.first]["address_line2"],
            address_line3: results[entries.first]["address_line3"],
            address_line4: results[entries.first]["address_line4"],
            town: results[entries.first]["town"],
            postcode: results[entries.first]["postcode"],
            country_code: results[entries.first]["country_code"],
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
                          country: if row["address_id"].include?("UPRN-") && check_uprn_exists?(row["address_id"][5..].to_i.to_s)
                                     [row["country_code"]]
                                   else
                                     UseCase::GetCountryForPostcode.new.execute(postcode: row["postcode"]).country_codes.map(&:to_s)
                                   end,
                          source:
                            if row["address_id"].include?("UPRN-") && check_uprn_exists?(row["address_id"][5..].to_i.to_s)
                              "GAZETTEER"
                            else
                              "PREVIOUS_ASSESSMENT"
                            end,
                          existing_assessments: row["existing_assessments"]
    end

    def check_uprn_exists?(uprn)
      sql = <<-SQL
        SELECT EXISTS(SELECT * FROM address_base WHERE uprn = $1)
      SQL

      bindings = [
        query_attribute("uprn", uprn),
      ]

      ActiveRecord::Base.connection.exec_query(sql, "SQL", bindings).first["exists"]
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

    def title_case_address(address)
      Gateway::AddressBaseHelper.title_case_address(address)
    end
  end
end
