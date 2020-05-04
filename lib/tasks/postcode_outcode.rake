require "csv"
require "open-uri"

desc "Import postcode_outcode geolocation data"

class PostcodeOutcodeGeolocation < ActiveRecord::Base; end

task :import_postcode_outcode do
  db = ActiveRecord::Base.connection

  db.execute("TRUNCATE TABLE postcode_outcode_geolocations RESTART IDENTITY")

  ActiveRecord::Base.logger = nil

  data = open("https://www.freemaptools.com/download/outcode-postcodes/postcode-outcodes.csv")

  CSV.foreach(data, headers: false) do |row|
    hash = {
      outcode: row[1],
      latitude: row[2],
      longitude: row[3],
    }
    PostcodeOutcodeGeolocation.create!(hash)
  end
end
