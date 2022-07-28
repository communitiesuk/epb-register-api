require "csv"
require "net/http"
require "aws-sdk-s3"
require "geocoder"
require_relative "./postcode_helper"

namespace :maintenance do
  desc "Clean up temporary tables following postcode data update"
  task :import_postcode_cleanup do
    delete_use_case = UseCase::DeleteGeolocationTables.new(Gateway::PostcodeGeolocationGateway.new)
    delete_use_case.execute
  end

  desc "Import postcode geolocation data"
  task :import_postcode, %i[file_name] do |_, args|
    postcode_gateway = Gateway::PostcodeGeolocationGateway.new
    delete_use_case = UseCase::DeleteGeolocationTables.new(postcode_gateway)
    delete_use_case.execute

    process_use_case = UseCase::ProcessPostcodeCsv.new(postcode_gateway)

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
