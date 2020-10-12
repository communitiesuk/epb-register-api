require "csv"
require "net/http"
require "geocoder"

desc "Import postcode geolocation data"

task :import_postcode do
  internal_url = ENV["url"]

  puts "Reading postcodes file from: #{internal_url}"

  uri = URI(internal_url)

  postcodes_csv = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  ) do |http|
    request = Net::HTTP::Get.new uri.request_uri
    request.basic_auth ENV["username"], ENV["password"]

    http.request request
  end

  puts "CSV table fetched"

  postcode_table = CSV.parse(postcodes_csv.body, headers: true)

  puts "CSV table parsed"

  region_codes = {
    E15000001: "North East",
    E15000002: "North West",
    E15000003: "Yorkshire and The Humber",
    E15000004: "East Midlands",
    E15000005: "West Midlands",
    E15000006: "Eastern",
    E15000007: "London",
    E15000008: "South East",
    E15000009: "South West",
    N07000001: "Northern Ireland",
    W08000001: "Wales",
  }

  db = ActiveRecord::Base.connection

  ActiveRecord::Base.logger = nil

  db.execute("DROP TABLE IF EXISTS update_postcode_geolocation")
  puts "If present update postcode table dropped"

  db.create_table :update_postcode_geolocation, force: :cascade do |t|
    t.string :postcode
    t.decimal :latitude
    t.decimal :longitude
    t.string :region
  end

  puts "New update postcode table created"

  results = []

  postcode_table.each do |row|
    postcode = row["pcd"]
    lat = row["lat"]
    long = row["long"]
    region = region_codes[row["eer"].to_sym]

    postcode = postcode.insert(-4, " ") if postcode[-4] != " "

    next if region.nil?

    results << [db.quote(postcode), lat, long, db.quote(region)].join(", ")
  end

  puts "Results formatted, number of results #{results.count}"

  results.each_slice(50_000) do |batch|
    batch = batch.join("), (")

    db.execute("INSERT INTO update_postcode_geolocation (postcode, latitude, longitude, region) VALUES(" + batch + ")")
  end

  number_of_rows = db.execute("SELECT COUNT(id) AS count FROM update_postcode_geolocation").first["count"]

  puts "Results batched and added to new table, number of results in table #{number_of_rows}"

  if number_of_rows == ENV["expected_number_of_rows"].to_i
    puts "expected numbers have been met"
    # Rename the old postcode table
    db.rename_table :postcode_geolocation, :previous_postcode_geolocation
    puts "Previous postcode table renamed"
    # Rename the temporary table to take its place
    db.rename_table :update_postcode_geolocation, :postcode_geolocation
    puts "Temporary update postcode table renamed"
    #  Drop the old table
    db.drop_table :previous_postcode_geolocation
    puts "Previous postcode table dropped"
  else
    puts "You expected " + ENV["expected_number_of_rows"] + " rows of data, but there were #{number_of_rows} added to the temporary table. \nIf the number of rows in the temporary table is correct please update your expected_number_of_rows environment variable and rerun the rake task "
  end
end
