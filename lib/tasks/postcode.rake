require "csv"
require "net/http"
require "aws-sdk-s3"
require "geocoder"

desc "Import postcode geolocation data"

task :import_postcode_cleanup do
  db = ActiveRecord::Base.connection

  db.drop_table :postcode_geolocation_tmp, if_exists: true
  db.drop_table :postcode_geolocation_legacy, if_exists: true
  puts "[#{Time.now}] Dropped postcode_geolocation_tmp / postcode_geolocation_legacy tables"

  db.drop_table :postcode_outcode_geolocations_tmp, if_exists: true
  db.drop_table :postcode_outcode_geolocations_legacy, if_exists: true
  puts "[#{Time.now}] Dropped postcode_outcode_geolocations_tmp / postcode_outcode_geolocations_legacy tables"
end

task :import_postcode do
  check_task_requirements
  file_name = ENV["file_name"]
  zipped = file_name.end_with?("zip")
  file_io = retrieve_file_on_s3(file_name)

  if zipped
    Zip::InputStream.open(file_io) do |csv_io|
      while (entry = csv_io.get_next_entry)
        next unless entry.size.positive?

        puts "[#{Time.now}] #{entry.name} was unzipped with a size of #{entry.size} bytes"
        postcode_csv = CSV.new(csv_io, headers: true)
        process_postcode_csv(postcode_csv)
      end
    end
  else
    puts "[#{Time.now}] Reading postcodes CSV file: #{ENV["file_name"]}"
    postcode_csv = CSV.new(file_io, headers: true)
    process_postcode_csv(postcode_csv)
  end
end

def check_task_requirements
  if ENV["bucket_name"].nil? && ENV["instance_name"].nil?
    abort("Please set the bucket_name or instance_name environment variable")
  end
  if ENV["file_name"].nil?
    abort("Please set the file_name environment variable")
  end
end

def retrieve_file_on_s3(file_name)
  storage_config_reader = Gateway::StorageConfigurationReader.new(
    bucket_name: ENV["bucket_name"],
    instance_name: ENV["instance_name"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)

  puts "[#{Time.now}] Retrieving from S3 file: #{file_name}"
  storage_gateway.get_file_io(file_name)
end

def process_postcode_csv(postcode_csv, buffer_size = 10000)
  create_postcode_table

  postcode_geolocation_buffer = []
  outcodes = {}

  row_number = 1
  while (row = postcode_csv.shift)
    postcode = row["pcd"]
    lat = row["lat"]
    long = row["long"]
    region = get_region_codes[row["eer"].to_sym]

    # Only considers England, NI and Wales
    next if region.nil?

    postcode = postcode.insert(-4, " ") if postcode[-4] != " "
    new_outcode = postcode.split(" ")[0]

    db = ActiveRecord::Base.connection
    postcode_geolocation_buffer << [db.quote(postcode), lat, long, db.quote(region)].join(", ")
    add_outcode(outcodes, new_outcode, lat, long, region)

    if row_number % buffer_size == 0
      insert_postcode_batch(postcode_geolocation_buffer)
      postcode_geolocation_buffer.clear
    end

    row_number += 1
  end

  # Insert and clear remaining postcode buffer
  unless postcode_geolocation_buffer.empty?
    insert_postcode_batch(postcode_geolocation_buffer)
    postcode_geolocation_buffer.clear
  end

  puts "[#{Time.now}] Inserted #{row_number} postcodes"

  create_outcode_table
  unless outcodes.empty?
    insert_outcodes(outcodes)
    puts "[#{Time.now}] Inserted #{outcodes.length} outcodes"
  end

  switch_postcode_table
  switch_outcode_table

  puts "[#{Time.now}] Postcode import completed"
end

def create_postcode_table
  db = ActiveRecord::Base.connection

  unless db.table_exists?(:postcode_geolocation_tmp)
    db.create_table :postcode_geolocation_tmp, primary_key: :postcode, id: :string, force: :cascade do |t|
      t.decimal :latitude
      t.decimal :longitude
      t.string :region
    end
    puts "[#{Time.now}] Created empty postcode_geolocation_tmp table"
  end
end

def create_outcode_table
  db = ActiveRecord::Base.connection

  unless db.table_exists?(:postcode_outcode_geolocations_tmp)
    db.create_table :postcode_outcode_geolocations_tmp, primary_key: :outcode, id: :string, force: :cascade do |t|
      t.decimal :latitude
      t.decimal :longitude
      t.string :region
    end
    puts "[#{Time.now}] Created empty postcode_outcode_geolocations_tmp table"
  end
end

def insert_postcode_batch(postcode_buffer)
  db = ActiveRecord::Base.connection

  batch = postcode_buffer.join("), (")
  db.exec_query("INSERT INTO postcode_geolocation_tmp (postcode, latitude, longitude, region) VALUES(" + batch + ")")
end

def add_outcode(outcodes, new_outcode, lat, long, region)
  unless outcodes.key?(new_outcode)
    outcodes[new_outcode] = {
      latitude: [],
      longitude: [],
      region: [],
    }
  end

  outcodes[new_outcode][:latitude].push(lat.to_f)
  outcodes[new_outcode][:longitude].push(long.to_f)
  outcodes[new_outcode][:region].push(region)
end

def switch_postcode_table
  db = ActiveRecord::Base.connection

  db.rename_table :postcode_geolocation, :postcode_geolocation_legacy
  puts "[#{Time.now}] Renamed table postcode_geolocation to postcode_geolocation_legacy"

  db.rename_table :postcode_geolocation_tmp, :postcode_geolocation
  puts "[#{Time.now}] Renamed table postcode_geolocation_tmp to postcode_geolocation"
end

def switch_outcode_table
  db = ActiveRecord::Base.connection

  db.rename_table :postcode_outcode_geolocations, :postcode_outcode_geolocations_legacy
  puts "[#{Time.now}] Renamed table postcode_outcode_geolocations to postcode_outcode_geolocations_legacy"

  db.rename_table :postcode_outcode_geolocations_tmp, :postcode_outcode_geolocations
  puts "[#{Time.now}] Renamed table postcode_outcode_geolocations_tmp to postcode_outcode_geolocations"
end

def insert_outcodes(outcodes)
  db = ActiveRecord::Base.connection

  batch = outcodes.map do |outcode, data|
    [
      db.quote(outcode),
      (data[:latitude].reduce(:+) / data[:latitude].size.to_f),
      (data[:longitude].reduce(:+) / data[:longitude].size.to_f),
      db.quote(data[:region].max_by { |i| data[:region].count(i) }),
    ].join(", ")
  end

  db.exec_query("INSERT INTO postcode_outcode_geolocations_tmp (outcode, latitude, longitude, region) VALUES(" + batch.join("), (") + ")")
end

def get_region_codes
  {
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
end
