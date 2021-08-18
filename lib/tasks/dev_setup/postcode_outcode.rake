require "csv"
require "open-uri"

namespace :dev_data do
  # This has been superceded for use in production by postcode.rake, but remains a
  # handy way to hack postcode data into local dev environment
  desc "Import postcode_outcode geolocation data to local dev environment"

  task :import_postcode_outcode do
    Tasks::TaskHelpers.quit_if_production
    db = ActiveRecord::Base.connection

    db.execute("TRUNCATE TABLE postcode_outcode_geolocations RESTART IDENTITY")

    ActiveRecord::Base.logger = nil

    data = open("https://www.freemaptools.com/download/uk-outcode-postcodes/postcode-outcodes.csv")

    CSV.foreach(data, headers: false) do |row|
      hash = {
        outcode: row[1],
        latitude: row[2],
        longitude: row[3],
      }
      PostcodeOutcodeGeolocation.create!(hash)
    end
  end
end

class PostcodeOutcodeGeolocation < ActiveRecord::Base; end
