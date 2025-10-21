require "csv"

namespace :dev_scripts do
  desc "Clean up temporary tables following postcode data update"
  task :s3_sample_address_match do
    bucket_name = ENV["BUCKET_NAME"]
    if bucket_name.nil?
      raise Boundary::ArgumentMissing, "bucket_name"
    end

    file_name = ENV["FILE_NAME"]
    if file_name.nil?
      raise Boundary::ArgumentMissing, "file_name"
    end

    output_file_name = "#{File.basename(file_name, '.csv')}_matched.csv"

    storage_gateway = ApiFactory.storage_gateway(bucket_name:)
    puts "[#{Time.now}] Retrieving from S3 file: #{file_name}"
    csv_io = storage_gateway.get_file_io(file_name)

    n = 1
    csv_string = CSV.generate do |csv_out|
      csv = CSV.new(csv_io, headers: true)
      addressing_gateway = Gateway::AddressingApiGateway.new
      headers = csv.first.headers + %w[uprn address confidednce]
      csv_out << headers
      csv.each do |row|
        matches = addressing_gateway.match_address(
          postcode: row["postcode"],
          address_line_1: row["address_line1"],
          address_line_2: row["address_line2"],
          address_line_3: row["address_line3"],
          address_line_4: row["address_line4"],
          town: row["town"],
        )
        n += 1

        best_match = matches.max_by { |m| m["confidence"].to_f }
        if best_match.nil?
          uprn = "none"
          address = "none"
          confidence = "none"
        else
          uprn = best_match["uprn"]
          address = best_match["address"]
          confidence = best_match["confidence"]
        end

        csv_out << row.fields + [uprn, address, confidence]
      end
    end
    storage_gateway.write_file(output_file_name, csv_string)
  end
end
