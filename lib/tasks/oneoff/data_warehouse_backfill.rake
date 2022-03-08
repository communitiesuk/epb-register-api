namespace :oneoff do
  desc "Export assessment IDs for date ranges towards data warehouse"
  task :backfill_to_data_warehouse, [:from_rrn, :until_time, :schema_type] do |_, args|
    from_rrn = args[:from_rrn]
    begin
      until_time = Time.parse args[:until_time]
    rescue ArgumentError
      puts "Could not parse a time from the until_time argument #{args[:until_time]}."
      next
    end
    is_dry_run = ENV["dry_run"] != "false"

    get_rrn_time_sql = "SELECT date_registered FROM assessments WHERE assessment_id=$1"
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

    rrn_date_registered = get_rrn_result.first["date_registered"]

    if rrn_date_registered < until_time
      puts "The RRN #{from_rrn} was registered #{rrn_date_registered}, which is before the time given in the until_time argument."
      next
    end

    target_schemas = args[:schema_type].split(";")

    count_assessments_to_export_sql = "SELECT COUNT(a.assessment_id) FROM assessments AS a INNER JOIN assessments_xml AS ax ON a.assessment_id=ax.assessment_id WHERE date_registered BETWEEN $1 AND $2 AND schema_type IN (#{target_schemas.map { |s| "'#{s}'" }.join(', ')})"
    count_assessments_to_export_binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "from",
        until_time,
        ActiveRecord::Type::DateTime.new,
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "to",
        rrn_date_registered,
        ActiveRecord::Type::DateTime.new,
      ),
    ]
    count_assessments_to_export_result = ActiveRecord::Base.connection.exec_query count_assessments_to_export_sql, "SQL", count_assessments_to_export_binds

    export_count = count_assessments_to_export_result.first["count"].to_i

    if export_count.zero?
      puts "There are no assessments in this range to export."
      next
    end

    if is_dry_run
      puts "#{export_count} assessments would be exported out to the data warehouse queue."
      puts "To run this export, run this command again with a dry_run=false option declared."
      next
    end

    puts "Exporting #{export_count} assessments out to the data warehouse queue..."

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    raw_connection = ActiveRecord::Base.connection.raw_connection
    get_assessment_ids_sql = "SELECT a.assessment_id FROM assessments AS a INNER JOIN assessments_xml AS ax ON a.assessment_id=ax.assessment_id WHERE date_registered BETWEEN '#{until_time.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{rrn_date_registered.strftime('%Y-%m-%d %H:%M:%S')}' AND schema_type IN (#{target_schemas.map { |s| "'#{s}'" }.join(', ')}) ORDER BY date_registered DESC"
    raw_connection.send_query get_assessment_ids_sql
    raw_connection.set_single_row_mode

    queues = ApiFactory.redis_gateway

    raw_connection.get_result.stream_each.map { |row| row["assessment_id"] }.each_slice(500) do |assessment_ids|
      queues.push_to_queue(:assessments, assessment_ids)
    end

    seconds_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    puts "Pushed #{export_count} assessments out to the data warehouse queue in #{seconds_elapsed}s."
  end
end
