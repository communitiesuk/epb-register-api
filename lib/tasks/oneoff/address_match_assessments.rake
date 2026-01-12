require "nokogiri"

namespace :oneoff do
  desc "Backfills matched_address_id"
  task :address_match_assessments do
    skip_existing = ENV["SKIP_EXISTING"]
    date_from = ENV["DATE_FROM"]
    date_to   = ENV["DATE_TO"]
    is_scottish = ENV["IS_SCOTTISH"] || false
    puts "[#{Time.now}] Starting address matching backfill (#{skip_existing ? 'skipping assessments with an existing match' : 'processing all assessments'})"

    addressing_api_gateway = Gateway::AddressingApiGateway.new
    assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
    event_broadcaster = Events::Broadcaster.new
    Events::Listener.new(event_broadcaster).attach_listeners
    match_assessment_address_use_case = UseCase::MatchAssessmentAddress.new(assessments_address_id_gateway:, event_broadcaster:, addressing_api_gateway:)
    ActiveRecord::Base.logger = nil
    db = ActiveRecord::Base.connection
    db_schema = is_scottish ? "scotland" : "public"

    find_unmatched_assessments_sql = <<-SQL
      SELECT a.assessment_id, a.address_line1, a.address_line2, a.address_line3, a.address_line4, a.postcode, a.town
      FROM #{db_schema}.assessments a
      JOIN #{db_schema}.assessments_address_id aai ON a.assessment_id = aai.assessment_id
    SQL

    if skip_existing
      find_unmatched_assessments_sql.concat("WHERE aai.matched_address_id IS NULL")
    end

    if date_from && date_to
      find_unmatched_assessments_sql.concat(" #{skip_existing ? 'AND' : 'WHERE'} date_registered BETWEEN '#{date_from}' AND '#{date_to}'")
    end

    unmatched_assessments = db.exec_query find_unmatched_assessments_sql
    puts "[#{Time.now}] Found #{unmatched_assessments.length} assessments to process"

    matched = 0
    match_not_found = 0
    unmatched_assessments.each do |unmatched_assessment|
      assessment_id = unmatched_assessment["assessment_id"]

      match = match_assessment_address_use_case.execute(
        assessment_id: assessment_id,
        postcode: unmatched_assessment["postcode"],
        address_line_1: unmatched_assessment["address_line1"],
        address_line_2: unmatched_assessment["address_line2"],
        address_line_3: unmatched_assessment["address_line3"],
        address_line_4: unmatched_assessment["address_line4"],
        town: unmatched_assessment["town"],
        is_scottish: is_scottish,
      )
      if !match.empty? && !%w[none unknown].include?(match)
        matched += 1
      else
        match_not_found += 1
      end
    end

    puts "[#{Time.now}] Finished backfilling matched address IDs, unmatched:#{match_not_found} matched:#{matched}"
  end
end
