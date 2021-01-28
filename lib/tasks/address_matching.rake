require "json"
require "csv"
require "aws-sdk-s3"

desc "Import address matching data from an S3 bucket"

task :clear_address_id_backup do
  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.drop_table :assessments_address_id_backup, if_exists: true
  puts "[#{Time.now}] Dropped temporary assessments_address_id_backup table"

  db.create_table :assessments_address_id_backup, primary_key: :assessment_id, id: :string do |t|
    t.string :address_id, index: true
    t.string :source
  end
  puts "[#{Time.now}] Created empty assessments_address_id_backup table"
end

task :import_address_matching do
  Signal.trap("INT") { throw :sigint }
  Signal.trap("TERM") { throw :sigterm }

  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  if ENV['bucket_name'].nil? and ENV['instance_name'].nil?
    abort("Please set the bucket_name or instance_name environment variable")
  end
  if ENV["file_name"].nil?
    abort("Please set the file_name environment variable")
  end
  file_name = ENV['file_name']

  storage_config_reader = Gateway::StorageConfigurationReader.new
  if ENV['instance_name'].nil?
    storage_config = storage_config_reader.get_local_configuration(ENV['bucket_name'])
  else
    storage_config = storage_config_reader.get_paas_configuration(ENV['instance_name'])
  end
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config)

  i = 0
  skipped = 0

  puts "[#{Time.now}] Starting downloading CSV file #{file_name}"
  file_io = storage_gateway.get_file_io(file_name)
  csv_contents = CSV.new(file_io)

  puts "[#{Time.now}] Starting processing CSV file"
  csv_contents.each do |csv_line|
    i += 1

    # uprn = csv_line[0]
    lprn = csv_line[1]
    rrn = csv_line[2]

    existing_backup = db.exec_query("SELECT 1 FROM assessments_address_id_backup aab " \
      "INNER JOIN assessments a USING (assessment_id) " \
      "WHERE a.address_id = '#{lprn}'")

    if existing_backup.empty?
      ActiveRecord::Base.transaction do
        db.exec_query("INSERT INTO assessments_address_id_backup " \
          "SELECT aa.* FROM assessments_address_id aa " \
          "INNER JOIN assessments a USING (assessment_id) " \
          "WHERE a.address_id = '#{lprn}'")

        db.exec_query("UPDATE assessments_address_id " \
          "SET address_id = '#{rrn}', source = 'lprn_without_os_uprn' " \
          "WHERE assessment_id IN (SELECT assessment_id from assessments WHERE address_id = '#{lprn}')")
      end
    else
      skipped += 1
    end

    if i % 10_000 == 0
      puts "[#{Time.now}] Processed #{i} LPRNs from CSV file, skipped #{skipped} present in backup table"
    end
  end

  puts "[#{Time.now}] Finished processing CSV file, #{i} LPRNs updated"

rescue StandardError => e
  catch(:sigint) do
    puts "#{e}"
    abort "Interrupted while downloading or processing CSV file at line #{i}"
  end
  catch(:sigterm) do
    abort "Killed while downloading or processing CSV file at line #{i}"
  end
  puts "Error while downloading or processing CSV file: #{e}"
end
