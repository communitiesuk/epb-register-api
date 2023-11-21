namespace :data_export do
  desc "Export assessment IDs from audit logs for the data warehouse"

  task :backfill_data_warehouse_from_events, %i[start_date end_date event_types] do |_, args|
    start_date = args.start_date || ENV["start_date"]
    end_date = args.end_date || ENV["end_date"]
    raise Boundary::ArgumentMissing, "start_date" unless start_date

    event_types = %w[opt_out opt_in cancelled]
    event_types.each do |type|
      ApiFactory.backfill_data_warehouse_by_events_use_case.execute(event_type: type, start_date:, end_date:)
    rescue Boundary::NoData => e
      puts e
    end
  end
end
