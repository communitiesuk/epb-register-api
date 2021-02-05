desc "Exporting assessments data for Open Data"

task :open_data_export do
   if ENV["bucket_name"].nil? && ENV["instance_name"].nil?
     abort("Please set the bucket_name or instance_name environment variable")
   end

   if ENV["assessment_type"].nil?
     abort("Please set the assessment_type environment variable")
   end

   if ENV["date_from"].nil?
     abort("Please set the date_from environment variable")
   end

   date_from = ENV["date_from"]

   export_open_data_use_case = nil

   if ENV["assessment_type"].upcase == "CEPC"
     export_open_data_use_case = UseCase::ExportOpenDataCommercial.new
   end

   if ENV["assessment_type"].upcase == "CEPC-RR"
     export_open_data_use_case = UseCase::ExportOpenDataCepcrr.new
   end

   if ENV["assessment_type"].upcase == "DEC"
     export_open_data_use_case = UseCase::ExportOpenDataDec.new
   end

   if ENV["assessment_type"].upcase == "DEC-RR"
     export_open_data_use_case = UseCase::ExportOpenDataDecrr.new
   end

   if ENV["assessment_type"].upcase == "SAP-RDSAP"
     export_open_data_use_case = UseCase::ExportOpenDataDomestic.new
   end

   storage_config_reader = Gateway::StorageConfigurationReader.new(
     bucket_name: ENV["bucket_name"],
     instance_name: ENV["instance_name"],
   )
   storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)

   date_time = DateTime.now.strftime("%Y%m%dT%H%M")

   data = Helper::ExportHelper.to_csv(export_open_data_use_case.execute.(date_from))

   storage_gateway.write_file("open_data_export_#{ENV["assessment_type"].downcase}_#{date_time}.csv", data)

  rescue StandardError => e
    abort "Error open data import failed: #{e}"

end



