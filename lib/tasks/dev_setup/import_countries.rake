# frozen_string_literal: true

namespace :dev_data do
  desc "Import countries data to local dev environment"
  task :import_countries do
    Tasks::TaskHelpers.quit_if_production

    ActiveRecord::Base.logger = nil
    connection = ActiveRecord::Base.connection

    table = "countries"
    file_path = "db/seed_data/#{table}.csv"
    connection.execute("TRUNCATE TABLE #{table} CASCADE")

    raw_connection = connection.raw_connection
    File.open(file_path) do |file|
      headers = file.readline
      raw_connection.copy_data("COPY #{table} (#{headers}) FROM STDIN (FORMAT csv, NULL '\\N')") do
        file.each { raw_connection.put_copy_data it }
      end
    end
    connection.execute(<<~SQL.squish)
      SELECT setval(
        pg_get_serial_sequence('#{table}', 'country_id'),
        COALESCE((SELECT MAX(country_id) + 1 FROM #{table}), 1),
        false
      );
    SQL
  end
end
