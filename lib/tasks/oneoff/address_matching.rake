require "json"
require "csv"
require "aws-sdk-s3"
require "nokogiri"
require_relative "./address_matching_helper"
require_relative "./address_table_helper"

namespace :oneoff do
  namespace :address_matching do
    desc "Clean up temporary table following address matching import"
    task :import_address_matching_cleanup do
      Tasks::TaskHelpers.quit_if_production
      ActiveRecord::Base.logger = nil
      db = ActiveRecord::Base.connection

      db.drop_table :assessments_address_id_backup, if_exists: true
      puts "[#{Time.now}] Dropped temporary assessments_address_id_backup table"
    end

    desc "Bootstrap the assessments_address_id table from LPRN->UPRN address matched data"
    # We have address matched data from Ordnance Survey that links some but not
    # all Landmark property identifiers to OS UPRNs.  This sets the address-matched
    # UPRN if it exists, and otherwise falls back to a RRN-based identifier
    task :import_address_matching do
      Tasks::TaskHelpers.quit_if_production
      Signal.trap("INT") { throw :sigint }
      Signal.trap("TERM") { throw :sigterm }
      ActiveRecord::Base.logger = nil

      AddressMatchingHelper.check_address_matching_requirements env: ENV
      AddressTableHelper.create_backup

      file_name = ENV["file_name"]
      counter = AddressMatchingHelper::Counter.new(processed: 0, skipped: 0)

      zipped = file_name.end_with?("zip")

      storage_config_reader = Gateway::StorageConfigurationReader.new(
        bucket_name: ENV["bucket_name"],
      )
      storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)

      puts "[#{Time.now}] Starting downloading CSV file #{file_name}"
      file_io = storage_gateway.get_file_io(file_name)

      puts "[#{Time.now}] Starting processing CSV file"

      if zipped
        Zip::InputStream.open(file_io) do |csv_io|
          while (entry = csv_io.get_next_entry)
            next unless entry.size.positive?

            puts "[#{Time.now}] #{entry.name} was unzipped with a size of #{entry.size} bytes"
            csv_content = CSV.new(csv_io, headers: true)
            AddressMatchingHelper.process_address_matching_csv csv_content, counter:
          end
        end
      else
        csv_content = CSV.new(file_io, headers: true)
        AddressMatchingHelper.process_address_matching_csv csv_content, counter:
      end

      puts "[#{Time.now}] Finished processing CSV file, #{counter.processed} LPRNs processed"
    rescue StandardError => e
      catch(:sigint) do
        puts e
        abort "Interrupted while downloading or processing CSV file at line #{counter.processed}"
      end
      catch(:sigterm) do
        abort "Killed while downloading or processing CSV file at line #{counter.processed}"
      end
      puts "Error while downloading or processing CSV file: #{e}"
    end

    desc "Clean up temporary table following missing address lines update"
    task :update_address_lines_cleanup do
      Tasks::TaskHelpers.quit_if_production
      ActiveRecord::Base.logger = nil
      db = ActiveRecord::Base.connection

      db.drop_table :address_lines_updated, if_exists: true
      puts "[#{Time.now}] Dropped temporary address_lines_updated table"
    end

    desc "Re-read address lines from lodged XML and add to the assessments table"
    # Some early migrations failed to write address lines into the assessments
    # table properly.  This task was made to back-fill empty addresses from the
    # source XML.
    task :update_address_lines do
      Tasks::TaskHelpers.quit_if_production
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
        assessment_id_query_attr = ActiveRecord::Relation::QueryAttribute.new("assessment_id", assessment_id, ActiveRecord::Type::String.new)
        assessment_xml = db.exec_query("SELECT xml, schema_type FROM assessments_xml WHERE assessment_id = $1", "SQL", [assessment_id_query_attr]).first
        if assessment_xml.nil?
          puts "[#{Time.now}] Could not read XML, skipping #{assessment_id}"
        else

          begin
            wrapper = ViewModel::Factory.new.create(assessment_xml["xml"], assessment_xml["schema_type"], assessment_id)
          rescue StandardError => e
            puts "[#{Time.now}] Exception in view model creation, skipping #{assessment_id}"
            puts "[#{Time.now}] #{e.message}"
            puts "[#{Time.now}] #{e.backtrace.first}"
            wrapper = nil
          end
          next if wrapper.nil?

          begin
            wrapper_hash = wrapper.to_hash
          rescue StandardError => e
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

          matching_assessment = db.exec_query("SELECT assessment_id, address_line1, address_line2, address_line3, address_line4 " \
            "FROM assessments WHERE assessment_id = $1", "SQL", [assessment_id_query_attr]).first

          prev_address_line1 = matching_assessment["address_line1"] || ""
          prev_address_line2 = matching_assessment["address_line2"] || ""
          prev_address_line3 = matching_assessment["address_line3"] || ""
          prev_address_line4 = matching_assessment["address_line4"] || ""

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
              AddressMatchingHelper.bind_string_attribute(update_binds, "address_line1", address_line1)
              AddressMatchingHelper.bind_string_attribute(update_binds, "address_line2", address_line2)
              AddressMatchingHelper.bind_string_attribute(update_binds, "address_line3", address_line3)
              AddressMatchingHelper.bind_string_attribute(update_binds, "address_line4", address_line4)
              AddressMatchingHelper.bind_string_attribute(update_binds, "assessment_id", assessment_id)
              db.exec_query(update_query, "SQL", update_binds)

              backup_query = <<-SQL
                INSERT INTO address_lines_updated(address_line1, address_line2, address_line3, address_line4, assessment_id)
                VALUES($1, $2, $3, $4, $5);
              SQL

              backup_binds = []
              AddressMatchingHelper.bind_string_attribute(backup_binds, "address_line1", prev_address_line1)
              AddressMatchingHelper.bind_string_attribute(backup_binds, "address_line2", prev_address_line2)
              AddressMatchingHelper.bind_string_attribute(backup_binds, "address_line3", prev_address_line3)
              AddressMatchingHelper.bind_string_attribute(backup_binds, "address_line4", prev_address_line4)
              AddressMatchingHelper.bind_string_attribute(backup_binds, "assessment_id", assessment_id)
              db.exec_query(backup_query, "SQL", backup_binds)

              updated_assessments += 1
            end
          end

        end
      end

      puts "[#{Time.now}] Address lines update complete: #{updated_assessments} assessments updated and #{matched_assessments} assessments matched"
    end
  end
end
