namespace :oneoff do
  desc "Fetch latest inserts and updated from the register and push onto queues"
  task :reload_queues do
    number_hours_before = ENV["NUMBER_HOURS_BEFORE"].nil? ? 1 : ENV["NUMBER_HOURS_BEFORE"].to_i
    utc_now = Time.now
    start_date = (utc_now - number_hours_before.hours)
    end_date = utc_now

    event_types =
      [{ type: "lodgement", queue: :assessments },
       { type: "address_id_updated", queue: :assessments_address_update },
       { type: "cancelled", queue: :cancelled },
       { type: "opt_out", queue: :opt_outs }]

    event_types.each do |i|
      assessment_ids = Helper::ReloadQueues.fetch_assessment_ids(event_type: i[:type], start_date:)
      ApiFactory.data_warehouse_queues_gateway.push_to_queue(i[:queue], assessment_ids.join(" ")) unless assessment_ids.nil? || assessment_ids.empty?
    end

    ENV["DATE_FROM"] = start_date.to_s
    ENV["DATE_TO"] = end_date.to_s
    Rake::Task["oneoff:address_match_assessments"].invoke
  end
end

class Helper::ReloadQueues
  def self.fetch_assessment_ids(event_type:, start_date:)
    sql = <<-SQL
            SELECT entity_id
            FROM audit_logs
            WHERE  timestamp BETWEEN '#{start_date.strftime('%Y-%m-%d %H:%M:%S')}' AND now()
            AND event_type = '#{event_type}'
    SQL
    ActiveRecord::Base.connection.exec_query(sql).map { |result| result["entity_id"] }
  end
end
