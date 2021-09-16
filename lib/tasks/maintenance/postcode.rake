require "csv"
require "net/http"
require "aws-sdk-s3"
require "geocoder"
require_relative "./postcode_helper"

namespace :maintenance do
  desc "Clean up temporary tables following postcode data update"
  task :import_postcode_cleanup do
    db = ActiveRecord::Base.connection

    db.drop_table :postcode_geolocation_tmp, if_exists: true
    db.drop_table :postcode_geolocation_legacy, if_exists: true
    puts "[#{Time.now}] Dropped postcode_geolocation_tmp / postcode_geolocation_legacy tables"

    db.drop_table :postcode_outcode_geolocations_tmp, if_exists: true
    db.drop_table :postcode_outcode_geolocations_legacy, if_exists: true
    puts "[#{Time.now}] Dropped postcode_outcode_geolocations_tmp / postcode_outcode_geolocations_legacy tables"
  end

  desc "Import postcode geolocation data"
  task :import_postcode, %i[file_name] do |_, args|
    file_name = args.file_name

    PostcodeHelper.check_task_requirements file_name: file_name,
                                           env: ENV
    zipped = file_name.end_with?("zip")
    file_io = PostcodeHelper.retrieve_file_on_s3 file_name: file_name,
                                                 env: ENV

    if zipped
      Zip::InputStream.open(file_io) do |csv_io|
        while (entry = csv_io.get_next_entry)
          next unless entry.size.positive?

          puts "[#{Time.now}] #{entry.name} was unzipped with a size of #{entry.size} bytes"
          postcode_csv = CSV.new(csv_io, headers: true)
          PostcodeHelper.process_postcode_csv(postcode_csv)
        end
      end
    else
      puts "[#{Time.now}] Reading postcodes CSV file: #{file_name}"
      postcode_csv = CSV.new(file_io, headers: true)
      PostcodeHelper.process_postcode_csv(postcode_csv)
    end
  end
end
