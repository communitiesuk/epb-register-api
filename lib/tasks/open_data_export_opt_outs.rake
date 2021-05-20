desc "Exporting hashed assessment_id opt out data for Open Data Communities"

task :open_data_export_opt_outs do
  bucket_name = ENV["BUCKET_NAME"]
  instance_name = ENV["INSTANCE_NAME"]

  raise Boundary::ArgumentMissing, "bucket_name or instance_name" unless bucket_name || instance_name

  exporter = ApiFactory.export_opt_outs_use_case
  data = exporter.execute

  raise Boundary::OpenDataEmpty if data.length.zero?

  csv_data = Helper::ExportHelper.to_csv(data)
  transmit_opt_out_file(csv_data)

rescue Boundary::RecoverableError => e
  error_output = {
    error: e.class.name,
  }

  error_output[:message] = e.message unless e.message == error_output[:error]
  begin
    error_output[:message] = JSON.parse error_output[:message] if error_output[:message]
  rescue JSON::ParserError
    # ignore
  end

rescue Boundary::TerminableError => e
  warn e.message
end

private

def transmit_opt_out_file(data)
  filename = "open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv"

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    instance_name: ENV["INSTANCE_NAME"],
    bucket_name: ENV["BUCKET_NAME"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  storage_gateway.write_file(filename, data)
end
