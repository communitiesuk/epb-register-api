require 'zip'
require 'net/http'
require 'geocoder'

desc 'Import postcode geolocation data'

task :import_postcode do
  db = ActiveRecord::Base.connection

  db.execute('TRUNCATE TABLE postcode_geolocation RESTART IDENTITY')

  ActiveRecord::Base.logger = nil


  uri = URI('https://www.freemaptools.com/download/full-postcodes/ukpostcodesmysql.zip')
  resp = Net::HTTP.get(uri)
  Zip::InputStream.open(StringIO.new(resp)) do |io|
    io.get_next_entry
    query = io.read.gsub 'INSERT INTO postcodelatlng (id,postcode,latitude,longitude) VALUES ', ''
    query = query.gsub "'',''", "'0', '0'"
    query = query.gsub ";", ","

    db.execute('INSERT INTO postcode_geolocation (id,postcode,latitude,longitude) VALUES ' + query[0...-3])
  end
end
