require "json"
require "csv"
require "aws-sdk-s3"
require "nokogiri"

desc "Update addresses in database from various sources"

task :import_address_matching_cleanup do
  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.drop_table :assessments_address_id_backup, if_exists: true
  puts "[#{Time.now}] Dropped temporary assessments_address_id_backup table"
end

task :import_address_matching do
  Signal.trap("INT") { throw :sigint }
  Signal.trap("TERM") { throw :sigterm }

  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  unless db.table_exists?(:assessments_address_id_backup)
    db.create_table :assessments_address_id_backup, primary_key: :assessment_id, id: :string do |t|
      t.string :address_id, index: true
      t.string :source
    end
    puts "[#{Time.now}] Created empty assessments_address_id_backup table"
  end

  if ENV["bucket_name"].nil? && ENV["instance_name"].nil?
    abort("Please set the bucket_name or instance_name environment variable")
  end
  if ENV["file_name"].nil?
    abort("Please set the file_name environment variable")
  end
  file_name = ENV["file_name"]

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    bucket_name: ENV["bucket_name"],
    instance_name: ENV["instance_name"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)

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
    puts e.to_s
    abort "Interrupted while downloading or processing CSV file at line #{i}"
  end
  catch(:sigterm) do
    abort "Killed while downloading or processing CSV file at line #{i}"
  end
  puts "Error while downloading or processing CSV file: #{e}"
end

task :update_address_lines_cleanup do
  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.drop_table :address_lines_updated, if_exists: true
  puts "[#{Time.now}] Dropped temporary address_lines_updated table"
end

task :update_address_lines do
  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  unless db.table_exists?(:address_lines_updated)
    db.create_table :address_lines_updated, primary_key: :assessment_id, id: :string do |t|
      t.string :address_line1
      t.string :address_line2
      t.string :address_line3
      t.string :address_line4
    end
    puts "[#{Time.now}] Created empty address_lines_updated table"
  end

  assessments = db.exec_query("SELECT assessment_id FROM assessments ORDER BY assessment_id ASC")
  last_updated = db.exec_query("SELECT max(assessment_id) FROM address_lines_updated").first
  last_updated_id = last_updated["max"]

  updated_assessments = 0
  matched_assessments = 0

  puts "[#{Time.now}] Found #{assessments.length} assessments"
  puts "[#{Time.now}] Starting from #{last_updated_id} (last updated)" unless last_updated_id.nil?
  assessments.each do |assessment|
    next if !last_updated_id.nil? && (assessment["assessment_id"] <= last_updated_id)

    assessment_id = assessment["assessment_id"]
    assessment_xml = db.exec_query("SELECT xml, schema_type FROM assessments_xml WHERE assessment_id = '#{assessment_id}'").first
    if assessment_xml.nil?
      puts "[#{Time.now}] Could not read XML, skipping #{assessment_id}"
    else

      begin
        wrapper = ViewModel::Factory.new.create(assessment_xml["xml"], assessment_xml["schema_type"], assessment_id)
        assessment_xml = nil
      rescue Exception => e
        puts "[#{Time.now}] Exception in view model creation, skipping #{assessment_id}"
        puts "[#{Time.now}] #{e.message}"
        puts "[#{Time.now}] #{e.backtrace.first}"
        wrapper = nil
      end
      next if wrapper.nil?

      begin
        wrapper_hash = wrapper.to_hash
        wrapper = nil
      rescue Exception => e
        puts "[#{Time.now}] Exception in wrapper to_hash, skipping #{assessment_id}"
        puts "[#{Time.now}] #{e.message}"
        puts "[#{Time.now}] #{e.backtrace.first}"
        wrapper_hash = nil
      end
      next if wrapper_hash.nil?

      address_line1 = wrapper_hash[:address][:address_line1]&.strip || ""
      address_line2 = wrapper_hash[:address][:address_line2]&.strip || ""
      address_line3 = wrapper_hash[:address][:address_line3]&.strip || ""
      address_line4 = wrapper_hash[:address][:address_line4]&.strip || ""
      wrapper_hash = nil

      matching_assessment = db.exec_query("SELECT assessment_id, address_line1, address_line2, address_line3, address_line4 " \
        "FROM assessments WHERE assessment_id = '#{assessment_id}'").first

      prev_address_line1 = matching_assessment["address_line1"] || ""
      prev_address_line2 = matching_assessment["address_line2"] || ""
      prev_address_line3 = matching_assessment["address_line3"] || ""
      prev_address_line4 = matching_assessment["address_line4"] || ""
      matching_assessment = nil

      if (prev_address_line1 == address_line1) &&
          (prev_address_line2 == address_line2) &&
          (prev_address_line3 == address_line3) &&
          (prev_address_line4 == address_line4)
        matched_assessments += 1
      else
        ActiveRecord::Base.transaction do
          update_query = <<-SQL
            UPDATE assessments
            SET address_line1 = $1,
                address_line2 = $2,
                address_line3 = $3,
                address_line4 = $4
            WHERE assessment_id = $5;
          SQL

          update_binds = []
          bind_string_attribute(update_binds, "address_line1", address_line1)
          bind_string_attribute(update_binds, "address_line2", address_line2)
          bind_string_attribute(update_binds, "address_line3", address_line3)
          bind_string_attribute(update_binds, "address_line4", address_line4)
          bind_string_attribute(update_binds, "assessment_id", assessment_id)
          db.exec_query(update_query, "SQL", update_binds)

          backup_query = <<-SQL
            INSERT INTO address_lines_updated(address_line1, address_line2, address_line3, address_line4, assessment_id)
            VALUES($1, $2, $3, $4, $5);
          SQL

          backup_binds = []
          bind_string_attribute(backup_binds, "address_line1", prev_address_line1)
          bind_string_attribute(backup_binds, "address_line2", prev_address_line2)
          bind_string_attribute(backup_binds, "address_line3", prev_address_line3)
          bind_string_attribute(backup_binds, "address_line4", prev_address_line4)
          bind_string_attribute(backup_binds, "assessment_id", assessment_id)
          db.exec_query(backup_query, "SQL", backup_binds)

          updated_assessments += 1
        end
      end

    end
  end

  puts "[#{Time.now}] Address lines update complete: #{updated_assessments} assessments updated and #{matched_assessments} assessments matched"
end

def bind_string_attribute(array, name, value)
  array << ActiveRecord::Relation::QueryAttribute.new(name, value, ActiveRecord::Type::String.new)
end
