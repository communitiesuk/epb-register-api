namespace :dev_data do
  desc "Import postcode_outcode geolocation data to local dev environment"
  task :import_postcode_outcode do
    Tasks::TaskHelpers.quit_if_production

    ActiveRecord::Base.logger = nil
    connection = ActiveRecord::Base.connection

    table = "postcode_outcode_geolocations"
    file_path = "db/seed_data/#{table}.csv"
    connection.execute("TRUNCATE TABLE #{table}")

    raw_connection = connection.raw_connection
    File.open(file_path) do |file|
      headers = file.readline
      raw_connection.copy_data("COPY #{table} (#{headers}) FROM STDIN (FORMAT csv, NULL '\N')") do
        file.each { raw_connection.put_copy_data it }
      end
    end
  end
end
