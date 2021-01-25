require "openssl"
require "csv"
require "zip"

desc "Import AddressBase data"

task :import_address_base do
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  INSERT_BATCH_SIZE = 50000

  if ENV['file_template'].nil?
    abort("Please set the file_template environment variable")
  end
  if ENV['bucket_name'].nil? and ENV['instance_name'].nil?
    abort("Please set the bucket_name or instance_name environment variable")
  end

  if ENV['number_of_files'].nil?
    puts("number_of_files environment variable not present, defaulting to 1")
    iterations = 1
  else
    iterations = ENV['number_of_files'].to_i
  end

  ActiveRecord::Base.logger = nil
  db = ActiveRecord::Base.connection

  db.drop_table :address_base_tmp, if_exists: true
  puts "[#{Time.now}] Dropped temporary address_base table"

  db.drop_table :address_base_legacy, if_exists: true
  puts "[#{Time.now}] Dropped legacy address_base table"

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

  storage_config_reader = Gateway::StorageConfigurationReader.new
  if ENV['instance_name'].nil?
    storage_config = storage_config_reader.get_local_configuration(ENV['bucket_name'])
  else
    storage_config = storage_config_reader.get_paas_configuration(ENV['instance_name'])
  end
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config)

  iterations.times do |iteration|
    # For example: AddressBasePlus_FULL_2020-12-11_{iterations}.csv.zip
    file_name = ENV['file_template'].gsub('{iteration}', (iteration + 1).to_s.rjust(3, '0'))
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
          query = []
          inserts.map do |row|
            uprn = ActiveRecord::Base.connection.quote(row[0])

            # 0 UPRN
            # 24 SAO_START_NUMBER, SAO_START_SUFFIX, SAO_END_NUMBER, SAO_END_SUFFIX, SAO_TEXT
            # 30 PAO_START_NUMBER, PAO_START_SUFFIX, PAO_END_NUMBER, PAO_END_SUFFIX, PAO_TEXT
            # 49 STREET_DESCRIPTION
            # 57 Locality
            # 61 Town name
            # 62 Administrative Area
            # 64 Postcode

            lines = []

            # If there is a SAO_text value, it should appear on a separate line above the PAO_text line (or the pao number/range + street line where there is no PAO_text value).
            # If there is a SAO_text value, it should always appear on its own line.
            lines.push(row[28])

            street = ""

            # If there is a PAO_text value, it should always appear on the line above the street name (or on the line above the <pao number string> + <street name> where there is a PAO number/range).
            if row[34] != ""
              # If there is a SAO number/range value, it should be inserted either on the same line as the PAO_text (if there is a PAO_text value), if there are both PAO_text and a PAO number/range, then the SAO number/range should appear on the same line as the PAO_text, and the PAO number/range should appear on the street line.
              line = []
              if row[24] != "" || row[25] != "" || row[26] != "" || row[27] != ""
                line.push([[row[24], row[25]].join(""), [row[26], row[27]].join("")].reject(&:blank?).join("-"))
              end
              line.push(row[34])
              lines.push(line.reject(&:blank?).join(" "))
              # or on the same line as the PAO number/range + street name (if there is only a PAO number/range value and no PAO_text value).
            elsif row[24] != "" || row[25] != "" || row[26] != "" || row[27] != ""
              street = [[row[24], row[25]].join(""), [row[26], row[27]].join("")].reject(&:blank?).join("-")
            end

            # Generally, if there is a PAO number/range string, it should appear on the same line as the street
            if row[30] != "" || row[31] != "" || !row[32] != "" || !row[33] != ""
              pao = [[row[30], row[31]].join(""), [row[32], row[33]].join("")].reject(&:blank?).join("-")
              street = [street, pao].reject(&:blank?).join(" ")
            end

            lines.push([street, row[49]].reject(&:blank?).join(" "))

            # The locality name (if present) should appear on a separate line beneath the street description,
            lines.push(row[57])

            # followed by the town name on the line below it. If there is no locality name, the town name should appear alone on the line beneath the street description.
            if row[57] != row[60]
              lines.push(row[60])
            end

            lines = lines.reject(&:blank?)

            # Finally, the postcode locator, if present, should be inserted on the final line of the address.
            postcode = row[64] == "" ? row[65] : row[64]

            # administrative_location if town is not the same
            #
            # STREET_DESCRIPTION

            town = row[60]

            query.push("(
                  #{uprn},
                  #{ActiveRecord::Base.connection.quote(postcode)},
                  #{ActiveRecord::Base.connection.quote(lines[0])},
                  #{ActiveRecord::Base.connection.quote(lines[1])},
                  #{ActiveRecord::Base.connection.quote(lines[2])},
                  #{ActiveRecord::Base.connection.quote(lines[3])},
                  #{ActiveRecord::Base.connection.quote(town)}
              )")
          end

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
