require "csv"

namespace :dev_scripts do
  desc "Clean up temporary tables following postcode data update"
  task :s3_sample_address_match do


    bucket_name = ENV["ONS_POSTCODE_BUCKET_NAME"]
    file_name = ENV["FILE_NAME"]

    storage_gateway = ApiFactory.storage_gateway(bucket_name:)
    puts "[#{Time.now}] Retrieving from S3 file: #{file_name}"
    csv_io = storage_gateway.get_file_io(file_name)
    pp csv_io
    csv = CSV.new(csv_io, headers: true)
    csv.each do |row|
      pp row
    end

  end
end

