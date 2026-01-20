require "nokogiri"

namespace :oneoff do
  desc "Backfills matched_uprn from assessments_address_id"
  task :address_match_assessments do
    skip_existing = ENV["SKIP_EXISTING"]
    batch_size = ENV["BATCH_SIZE"].nil? ? 1000 : ENV["BATCH_SIZE"].to_i
    date_from = ENV["DATE_FROM"]
    date_to   = ENV["DATE_TO"]
    is_scottish = ENV["IS_SCOTTISH"] || false
    puts "[#{Time.now}] Starting address matching backfill (#{skip_existing ? 'skipping assessments with an existing match' : 'processing all assessments'})"

    addressing_gateway = Gateway::AddressingApiGateway.new
    Gateway::AssessmentsAddressIdGateway.new

    ActiveRecord::Base.logger = nil
    db = ActiveRecord::Base.connection
    db_schema = is_scottish ? "scotland" : "public"

    find_unmatched_assessments_sql = <<-SQL
      SELECT a.assessment_id, a.address_line1, a.address_line2, a.address_line3, a.address_line4, a.postcode, a.town
      FROM #{db_schema}.assessments a
      JOIN #{db_schema}.assessments_address_id aai ON a.assessment_id = aai.assessment_id
    SQL

    if skip_existing
      find_unmatched_assessments_sql.concat("WHERE aai.matched_uprn IS NULL")
    end

    if date_from && date_to
      find_unmatched_assessments_sql.concat(" #{skip_existing ? 'AND' : 'WHERE'} date_registered BETWEEN '#{date_from}' AND '#{date_to}'")
    end

    unmatched_assessments = db.exec_query find_unmatched_assessments_sql
    puts "[#{Time.now}] Found #{unmatched_assessments.length} assessments to process"
    assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
    data_warehouse_queues_gateway = Gateway::DataWarehouseQueuesGateway.new
    unmatched_assessments.each_slice(batch_size) do |batch|
      arr_matches = []
      payload = []

      batch.each do |unmatched_assessment|
        assessment_id = unmatched_assessment["assessment_id"]

        matches = addressing_gateway.match_address(
          postcode: unmatched_assessment["postcode"],
          address_line_1: unmatched_assessment["address_line1"],
          address_line_2: unmatched_assessment["address_line2"],
          address_line_3: unmatched_assessment["address_line3"],
          address_line_4: unmatched_assessment["address_line4"],
          town: unmatched_assessment["town"],
        )

        if matches.empty?
          matched_uprn = nil
          confidence = nil?
        elsif matches.length == 1
          matched_uprn = matches.first["uprn"]
          confidence = matches.first["confidence"]
        else
          best_confidence = matches.max_by { |m| m["confidence"].to_f }["confidence"]
          best_matches = matches.select { |m| m["confidence"] == best_confidence }
          if best_matches.length == 1
            matched_uprn = best_matches.first["uprn"]
            confidence = best_matches.first["confidence"]
          else
            matched_uprn = "unknown"
            confidence = best_confidence
          end
        end
        arr_matches << "('#{assessment_id}', '#{matched_uprn}', #{confidence})" if matched_uprn
        payload << "#{assessment_id}:#{matched_uprn}" if matched_uprn && matched_uprn != "unknown"
      end

      assessments_address_id_gateway.update_matched_batch(arr_matches, is_scottish) unless arr_matches.empty?

      if Helper::Toggles.enabled?("notify-data-warehouse-matched-uprn") && !(is_scottish || payload.empty?)
        data_warehouse_queues_gateway.push_to_queue(:backfill_matched_address_update, payload)
      end
    end
  end
end
