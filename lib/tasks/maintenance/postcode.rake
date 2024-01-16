require "csv"
require "net/http"
require "aws-sdk-s3"
require "geocoder"
require_relative "./postcode_helper"
require "open-uri"

namespace :maintenance do
  desc "Clean up temporary tables following postcode data update"
  task :delete_postcode_geo_location_tables do
    delete_use_case = ApiFactory.delete_geolocation_tables
    delete_use_case.execute
  end

  desc "Import postcode geolocation data"
  task :import_postcode_geo_location, %i[file_name] do |_, args|
    ons_bucket_name = ENV["ONS_POSTCODE_BUCKET_NAME"]
    delete_use_case = ApiFactory.delete_geolocation_tables
    delete_use_case.execute

    process_use_case = ApiFactory.process_postcode_csv

    file_name = args.file_name || ENV["FILE_NAME"]

    PostcodeHelper.check_task_requirements file_name:,
                                           bucket_name: ons_bucket_name
    zipped = file_name.end_with?("zip")
    file_io = PostcodeHelper.retrieve_file_on_s3 file_name:,
                                                 bucket_name: ons_bucket_name

    if zipped
      Zip::InputStream.open(file_io) do |csv_io|
        while (entry = csv_io.get_next_entry)
          next unless entry.size.positive?

          puts "[#{Time.now}] #{entry.name} was unzipped with a size of #{entry.size} bytes"
          postcode_csv = CSV.new(csv_io, headers: true)
          process_use_case.execute(postcode_csv)
        end
      end
    else
      puts "[#{Time.now}] Reading postcodes CSV file: #{file_name}"
      postcode_csv = CSV.new(file_io, headers: true)

      process_use_case.execute(postcode_csv)
    end
  end
end
