namespace :oneoff do
  desc "Fetch latest inserts and updated from the register and push onto queues"
  task :reload_queues do
    number_hours_before = ENV["NUMBER_HOURS_BEFORE"].to_i || 1

    start_date = Time.now - number_hours_before.hours
    end_date = Time.now.to_s
    event_types =
      [{ type: "lodgement", queue: :assessments },
       { type: "address_id_updated", queue: :assessments_address_update },
       { type: "cancelled", queue: :cancelled },
       { type: "opt_out", queue: :opt_outs }]

    event_types.each do |i|
      assessment_ids = ApiFactory.audit_logs_gateway.fetch_assessment_ids(event_type: i[:type], start_date:)
      ApiFactory.data_warehouse_queues_gateway.push_to_queue(i[:queue], assessment_ids) unless assessment_ids.nil?
    end
    ENV["DATE_FROM"] = start_date.to_s
    ENV["DATE_TO"] = end_date
    Rake::Task["oneoff:address_match_assessments"].invoke
  end
end
