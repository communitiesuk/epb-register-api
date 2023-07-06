namespace :data_export do
  desc "Export assessment IDs for date ranges towards data warehouse"

  task :backfill_data_warehouse, %i[rrn start_date schema_type] do |_, args|
    rrn = args.rrn || ENV["rrn"]
    start_date = args.start_date || ENV["start_date"]
    schema_type = args.schema_type || ENV["schema_type"]
    raise Boundary::ArgumentMissing, "rrn" unless rrn
    raise Boundary::ArgumentMissing, "start_date" unless start_date
    raise Boundary::ArgumentMissing, "schema_type" unless schema_type

    use_case = ApiFactory.backfill_data_warehouse_use_case

    use_case.execute(rrn:, start_date:, schema_type:)
  end
end
