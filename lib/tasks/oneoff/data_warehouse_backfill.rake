namespace :oneoff do
  desc "Export assessment IDs for date ranges towards data warehouse"
  task :backfill_to_data_warehouse, [:from_rnn, :until_time] do |_, args|
    from_rrn = args[:from_rnn]
    begin
      until_time = Time.parse args[:until_time]
    rescue ArgumentError
      puts "Could not parse a time from the until_time argument #{args[:until_time]}."
      next
    end

    get_rrn_time_sql = "SELECT created_at FROM assessments WHERE assessment_id=$1 AND created_at IS NOT NULL"
    get_rrn_binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "assessment_id",
        from_rrn,
        ActiveRecord::Type::String.new,
      ),
    ]
    get_rrn_result = ActiveRecord::Base.connection.exec_query get_rrn_time_sql, "SQL", get_rrn_binds
    if get_rrn_result.empty?
      puts "The RRN #{from_rrn} could not be found, so no export is possible."
      next
    end

    rrn_created_at = get_rrn_result.first["created_at"]

    if rrn_created_at < until_time
      puts "The RRN #{from_rrn} was created at #{rrn_created_at}, which is before the time given in the until_time argument."
      next
    end

    count_assessments_to_export_sql = "SELECT COUNT(assessment_id) FROM assessments WHERE created_at BETWEEN $1 AND $2"
    count_assessments_to_export_binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "from",
        until_time,
        ActiveRecord::Type::DateTime.new,
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "to",
        rrn_created_at,
        ActiveRecord::Type::DateTime.new,
      ),
    ]
    count_assessments_to_export_result = ActiveRecord::Base.connection.exec_query count_assessments_to_export_sql, "SQL", count_assessments_to_export_binds

    export_count = count_assessments_to_export_result.first["count"].to_i

    if export_count.zero?
      puts "There are no assessments in this range to export."
      next
    end

    puts "OK to export #{export_count} assessments out to the data warehouse queues? (Y/N)"

    unless $stdin.gets.chomp == "Y"
      puts "Exiting without performing an export."
      next
    end

    current_schemas = %w[CEPC-8.0.0 CEPC-NI-8.0.0 RdSAP-Schema-20.0.0 RdSAP-Schema-NI-20.0.0 SAP-Schema-18.0.0 SAP-Schema-NI-18.0.0]

    raw_connection = ActiveRecord::Base.connection.raw_connection
    get_assessment_ids_sql = "SELECT a.assessment_id FROM assessments AS a INNER JOIN assessments_xml AS ax ON a.assessment_id=ax.assessment_id WHERE created_at BETWEEN '#{until_time.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{rrn_created_at.strftime('%Y-%m-%d %H:%M:%S')}' AND schema_type IN (#{current_schemas.map { |s| "'#{s}'" }.join(', ')}) ORDER BY created_at DESC"
    raw_connection.send_query get_assessment_ids_sql
    raw_connection.set_single_row_mode

    queues = ApiFactory.redis_gateway

    raw_connection.get_result.stream_each.map { |row| row["assessment_id"] }.each_slice(500) do |assessment_ids|
      queues.push_to_queue(:assessments, assessment_ids)
    end

    puts "Pushed #{export_count} assessments to the data warehouse queue."
  end
end
