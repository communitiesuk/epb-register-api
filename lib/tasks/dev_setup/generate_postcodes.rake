require "csv"
require "open-uri"

namespace :dev_data do
  # This has been superceded for use in production by postcode.rake, but remains a
  # handy way to hack postcode data into local dev environment
  # We don't just import the postcodes because we don't need that many, currently generating them off the outcodes we have is fine
  desc "Import postcodes geolocation data to local dev environment"

  task :generate_postcodes do
    Tasks::TaskHelpers.quit_if_production
    db = ActiveRecord::Base.connection

    db.execute("TRUNCATE TABLE postcode_geolocation RESTART IDENTITY")

    ActiveRecord::Base.logger = nil

    outcodes = ActiveRecord::Base.connection.exec_query("SELECT * FROM postcode_outcode_geolocations ORDER BY random() LIMIT 50")

    outcodes.each do |row|
      hash = {
        postcode: "#{row['outcode']} #{rand(0..9)}#{('A'..'Z').to_a.sample(2).join}",
        latitude: row['latitude'],
        longitude: row['longitude'],
      }
      PostcodeGeolocation.create!(hash)
    end
  end
end


class PostcodeGeolocation < ActiveRecord::Base
  self.table_name = "postcode_geolocation"
end
