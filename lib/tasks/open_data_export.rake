desc "Exporting assessments data for Open Data"

task :open_data_export_cepc do
   if ENV["bucket_name"].nil? && ENV["instance_name"].nil?
     abort("Please set the bucket_name or instance_name environment variable")
   end

   # This is used to switch between local and Gov Paas
   storage_config_reader = Gateway::StorageConfigurationReader.new(
     bucket_name: ENV["bucket_name"],
     instance_name: ENV["instance_name"],
   )
   storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)

   export_open_data_commercial = UseCase::ExportOpenDataCommercial.new
   data = Helper::ExportHelper.to_csv(export_open_data_commercial.execute)
   storage_gateway.write_file("open_data_export_cepc_#{DateTime.now}.csv", data)

  rescue StandardError => e
    abort "Error open data import failed: #{e}"

end


