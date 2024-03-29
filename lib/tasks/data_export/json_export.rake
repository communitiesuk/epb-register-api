namespace :ad_hoc_data do
  desc "Export assessment data to a JSON format in files in an S3 bucket"
  task :json_export do
    start_date = ENV["start_date"]
    bucket_name = ENV["bucket_name"]

    raise Boundary::ArgumentMissing, "start_date" unless start_date
    raise Boundary::ArgumentMissing, "bucket_name" unless bucket_name

    puts "[#{Time.now}] Starting JSON export task"

    exporter = ApiFactory.assessments_export_use_case
    exports = exporter.execute(start_date)

    puts "[#{Time.now}] #{exports.size} files to export"

    storage_gateway = ApiFactory.storage_gateway(
      bucket_name:,
    )
    exports.each do |export|
      filename = "export/#{export[:assessment_id]}.json"
      data = export[:data]
      storage_gateway.write_file(filename, data.to_json)
    end

    puts "[#{Time.now}] JSON export task completed"
  end
end
