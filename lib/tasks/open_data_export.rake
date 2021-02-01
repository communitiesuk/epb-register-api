desc "Exporting assessments data for Open Data"

task :open_data_export_cepc do
   if ENV["bucket_name"].nil? && ENV["instance_name"].nil?
     abort("Please set the bucket_name or instance_name environment variable")
   end
   # This is used to switch between local and Gov Paas
   storage_config_reader = Gateway::StorageConfigurationReader.new
   storage_config = if ENV["instance_name"].nil?
                      storage_config_reader.get_local_configuration(ENV["bucket_name"])
                    else
                      storage_config_reader.get_paas_configuration(ENV["instance_name"])
                    end
   storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config)

   export_open_data_commercial = UseCase::ExportOpenDataCommercial.new
   data = Helper::ExportHelper.to_csv(export_open_data_commercial.execute)
   storage_gateway.write_file('open_data_export_cepc', data)

  rescue StandardError => e
    puts e
    puts "File could not be uploaded"

end


