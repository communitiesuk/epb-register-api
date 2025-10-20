require "csv"

namespace :dev_scripts do
  desc "Clean up temporary tables following postcode data update"
  task :s3_sample_address_match do


    bucket_name = ENV["ONS_POSTCODE_BUCKET_NAME"]
    file_name = ENV["FILE_NAME"]

    storage_gateway = ApiFactory.storage_gateway(bucket_name:)
    puts "[#{Time.now}] Retrieving from S3 file: #{file_name}"
    csv_io = storage_gateway.get_file_io(file_name)
    csv = CSV.new(csv_io, headers: true)
    addressing_gateway = Gateway::AddressingApiGateway.new
    csv.each do |row|
      addressing_gateway.match_address(
        postcode: row["postcode"],
        address_line_1: row["address_line1"],
        address_line_2: row["address_line2"],
        address_line_3: row["address_line3"],
        address_line_4: row["address_line4"],
        town: row["town"])
    end

  end
end

