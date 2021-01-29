desc "Exporting assessments data for Open Data"

def file_path(name)
  "./spec/fixtures/open_data_export/#{name}.csv"
end

def write_to_file(name, data)
  File.write(file_path(name).to_s, data)
end

def delete_data_after_stream
  File.write(file_path(name).to_s, "")
end

def get_storage
  storage_configuration = Gateway::StorageConfigurationReader.new

  pp  storage_configuration.get_paas_configuration("paas-s3-broker-prod-lon-22adb93a-1349-49fd-b9b7-faca4872addb")
  storage_configuration.get_paas_configuration("paas-s3-broker-prod-lon-22adb93a-1349-49fd-b9b7-faca4872addb")


end

task :open_data_export_cepc do
   export_open_data_commercial = UseCase::ExportOpenDataCommercial.new
   data = Helper::ExportHelper.to_csv(export_open_data_commercial.execute) #this will go to standard output
   write_to_file("cepc", data)
   begin
     raise 'This exception will be rescued!'
     object_uploaded?(get_storage, file_path("cepc"))
     puts true
   rescue StandardError => e
     puts "File could not be uploaded"
   end

end


task :open_data_export_dec do
  export_open_data_commercial = UseCase::ExportOpenDataDec.new
  data = Helper::ExportHelper.to_csv(export_open_data_commercial.execute) #this will go to standard output
  write_to_file("dec",data)
end




# Uploads an object to a bucket in Amazon Simple Storage Service (Amazon S3).
#
# Prerequisites:
#
# - An S3 bucket.
# - An object to upload to the bucket.
#
# @param s3_client [Aws::S3::Resource] An initialized S3 resource.
# @param bucket_name [String] The name of the bucket.
# @param object_key [String] The name of the object.
# @param file_path [String] The path and file name of the object to upload.
# @return [Boolean] true if the object was uploaded; otherwise, false.
# @example
#   exit 1 unless object_uploaded?(
#     Aws::S3::Resource.new(region: 'us-east-1'),
#     'doc-example-bucket',
#     'my-file.txt',
#     './my-file.txt'
#   )
def object_uploaded?(s3_resource, file_path, bucket_name="epb-open-data-export")

  object = s3_resource.bucket(bucket_name).object(object_key)
  object.upload_file(file_path)
  true
rescue StandardError => e
  puts "Error uploading object: #{e.message}"
  false
end


