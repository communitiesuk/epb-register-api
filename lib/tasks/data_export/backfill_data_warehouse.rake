namespace :data_export do
  desc "Export assessment IDs for date ranges towards data warehouse"

  task :backfill_data_warehouse, %i[start_date end_date type_of_assessment] do |_, args|
    start_date = args.start_date || ENV["start_date"]
    type_of_assessment = args.schema_type || ENV["type_of_assessment"]
    end_date = args.end_date || ENV["end_date"]
    raise Boundary::ArgumentMissing, "start_date" unless start_date

    use_case = ApiFactory.backfill_data_warehouse_use_case
    use_case.execute(start_date:, end_date:, type_of_assessment:)
  end
end
