require "openssl"
require "csv"
require "zip"

namespace :maintenance do
  namespace :address_base do
    desc "Drop temporary tables associated with AddressBase imports"
    task :cleanup do
      ActiveRecord::Base.logger = nil
      db = ActiveRecord::Base.connection

      db.drop_table :address_base_tmp, if_exists: true
      puts "[#{Time.now}] Dropped address_base_tmp table"

      db.drop_table :address_base_legacy, if_exists: true
      puts "[#{Time.now}] Dropped address_base_legacy table"
    end

    desc "Rollback to previous addressBase table (eg following a borked import)"
    task :restore do
      ActiveRecord::Base.logger = nil
      db = ActiveRecord::Base.connection

      db.rename_table :address_base, :address_base_tmp
      puts "[#{Time.now}] Switched address_base to address_base_tmp"

      db.rename_table :address_base_legacy, :address_base
      puts "[#{Time.now}] Restored address_base_legacy as address_base"
    end

    desc "Import AddressBase data from a set of AddressBasePlus data files in S3"
    task :import do
      INSERT_BATCH_SIZE = 50_000
      ADDRESS_BASE_HEADERS = %w[UPRN UDPRN CHANGE_TYPE STATE STATE_DATE CLASS PARENT_UPRN X_COORDINATE Y_COORDINATE LATITUDE LONGITUDE RPC LOCAL_CUSTODIAN_CODE COUNTRY LA_START_DATE LAST_UPDATE_DATE ENTRY_DATE RM_ORGANISATION_NAME LA_ORGANISATION DEPARTMENT_NAME LEGAL_NAME SUB_BUILDING_NAME BUILDING_NAME BUILDING_NUMBER SAO_START_NUMBER SAO_START_SUFFIX SAO_END_NUMBER SAO_END_SUFFIX SAO_TEXT ALT_LANGUAGE_SAO_TEXT PAO_START_NUMBER PAO_START_SUFFIX PAO_END_NUMBER PAO_END_SUFFIX PAO_TEXT ALT_LANGUAGE_PAO_TEXT USRN USRN_MATCH_INDICATOR AREA_NAME LEVEL OFFICIAL_FLAG OS_ADDRESS_TOID OS_ADDRESS_TOID_VERSION OS_ROADLINK_TOID OS_ROADLINK_TOID_VERSION OS_TOPO_TOID OS_TOPO_TOID_VERSION VOA_CT_RECORD VOA_NDR_RECORD STREET_DESCRIPTION ALT_LANGUAGE_STREET_DESCRIPTION DEPENDENT_THOROUGHFARE THOROUGHFARE WELSH_DEPENDENT_THOROUGHFARE WELSH_THOROUGHFARE DOUBLE_DEPENDENT_LOCALITY DEPENDENT_LOCALITY LOCALITY WELSH_DEPENDENT_LOCALITY WELSH_DOUBLE_DEPENDENT_LOCALITY TOWN_NAME ADMINISTRATIVE_AREA POST_TOWN WELSH_POST_TOWN POSTCODE POSTCODE_LOCATOR POSTCODE_TYPE DELIVERY_POINT_SUFFIX ADDRESSBASE_POSTAL PO_BOX_NUMBER WARD_CODE PARISH_CODE RM_START_DATE MULTI_OCC_COUNT VOA_NDR_P_DESC_CODE VOA_NDR_SCAT_CODE ALT_LANGUAGE].map(&:to_sym)

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
        t.string "classification_code", limit: 6
        t.string "address_type", limit: 15
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

            csv_contents = CSV.new(csv_io, headers: ADDRESS_BASE_HEADERS)
            puts "[#{Time.now}] #{entry.name} parsed successfully as CSV"

            i = 0
            csv_contents.each_slice(INSERT_BATCH_SIZE).reject(&:empty?).each do |inserts|
              query = inserts.map { |row|
                import_address_data_use_case.execute(row)
              }.compact

              next if query.empty?

              db.exec_query("INSERT INTO address_base_tmp VALUES #{query.join(', ')}")
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
  end
end
