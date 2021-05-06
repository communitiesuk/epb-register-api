require "openssl"
require "csv"
require "zip"

desc "Import AddressBase data"

task :cleanup_address_base do
  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.drop_table :address_base_tmp, if_exists: true
  puts "[#{Time.now}] Dropped address_base_tmp table"

  db.drop_table :address_base_legacy, if_exists: true
  puts "[#{Time.now}] Dropped address_base_legacy table"
end

task :restore_legacy_address_base do
  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.rename_table :address_base, :address_base_tmp
  puts "[#{Time.now}] Switched address_base to address_base_tmp"

  db.rename_table :address_base_legacy, :address_base
  puts "[#{Time.now}] Restored address_base_legacy as address_base"
end

task :import_address_base do
  INSERT_BATCH_SIZE = 50_000

  if ENV["file_template"].nil?
    abort("Please set the file_template environment variable")
  end
  if ENV["bucket_name"].nil? && ENV["instance_name"].nil?
    abort("Please set the bucket_name or instance_name environment variable")
  end

  if ENV["number_of_files"].nil?
    puts("number_of_files environment variable not present, defaulting to 1")
    iterations = 1
  else
    iterations = ENV["number_of_files"].to_i
  end

  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.drop_table :address_base_tmp, if_exists: true
  puts "[#{Time.now}] Dropped address_base_tmp table"

  db.drop_table :address_base_legacy, if_exists: true
  puts "[#{Time.now}] Dropped address_base_legacy table"

  puts "[#{Time.now}] Starting address base import"

  db.create_table "address_base_tmp", primary_key: "uprn", id: :string, force: :cascade do |t|
    t.string "postcode"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.string "town"
  end
  puts "[#{Time.now}] Created empty address_base_tmp table"

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    bucket_name: ENV["bucket_name"],
    instance_name: ENV["instance_name"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)

  import_address_data_use_case = UseCase::ImportAddressBaseData.new

  iterations.times do |iteration|
    # For example: AddressBasePlus_FULL_2020-12-11_{iterations}.csv.zip
    file_name = ENV["file_template"].gsub("{iteration}", (iteration + 1).to_s.rjust(3, "0"))
    puts "[#{Time.now}] Downloading file #{file_name} from storage"
    file_io = storage_gateway.get_file_io(file_name)

    puts "[#{Time.now}] Unzipping file #{file_name}"
    Zip::InputStream.open(file_io) do |csv_io|
      while (entry = csv_io.get_next_entry)
        next unless entry.size.positive?

        puts "[#{Time.now}] #{entry.name} was unzipped with a size of #{entry.size} bytes"

        csv_contents = CSV.new(csv_io)
        puts "[#{Time.now}] #{entry.name} parsed successfully as CSV"

        i = 0
        csv_contents.each_slice(INSERT_BATCH_SIZE) do |inserts|
          query = inserts.map do |row|
            import_address_data_use_case.execute(row)
          end.compact

          db.exec_query("INSERT INTO address_base_tmp VALUES " + query.join(", "))
          i += INSERT_BATCH_SIZE
          puts "[#{Time.now}] Inserted #{i} addresses from #{entry.name}"
        end

        puts "[#{Time.now}] #{file_name} was imported successfully"
      end
    end
  end

  number_of_rows = db.exec_query("SELECT COUNT(uprn) AS number_of_addresses FROM address_base_tmp").first["number_of_addresses"]
  puts "[#{Time.now}] #{number_of_rows} addresses were inserted in address_base_tmp"

  db.add_index :address_base_tmp, :postcode
  puts "[#{Time.now}] Created address_base_tmp postcode index"

  db.rename_table :address_base, :address_base_legacy
  puts "[#{Time.now}] Renamed address_base table"

  db.rename_table :address_base_tmp, :address_base
  puts "[#{Time.now}] Switched address_base_tmp as new address_base table"
end
