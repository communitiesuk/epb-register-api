require 'zip'
require 'net/http'

desc 'Import postcode geolocation data'

task :postcode do
  db = ActiveRecord::Base.connection

  db.execute('TRUNCATE TABLE postcode_geolocation')

  ActiveRecord::Base.logger = nil

  uri = URI('https://www.freemaptools.com/download/full-postcodes/ukpostcodesmysql.zip')
  resp = Net::HTTP.get(uri)
  Zip::InputStream.open(StringIO.new(resp)) do |io|
    entry = io.get_next_entry
    query = io.read.gsub 'postcodelatlng', 'postcode_geolocation'
    query = query.gsub "'',''", "'0', '0'"

    query.split(';').each do |sql|
      db.execute(sql)
    end
  end
end
