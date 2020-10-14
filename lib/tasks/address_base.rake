require "openssl"
require "csv"
require "zip"

desc "Truncate AddressBase data"

task :truncate_address_base do
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE address_base RESTART IDENTITY CASCADE")
end

desc "Import AddressBase data"

task :import_address_base do
  ActiveRecord::Base.logger = nil

  iterations = ENV["iterations"] ? ENV["iterations"].to_i : 1

  db = ActiveRecord::Base.connection

  puts "Starting extraction at #{Time.now}"

  db.execute("DROP TABLE IF EXISTS address_base_tmp")

  db.create_table "address_base_tmp", primary_key: "uprn", id: :string, force: :cascade do |t|
    t.string "postcode"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.string "town"
  end

  puts "address_base_tmp table created at #{Time.now}"

  iterations.times do |iteration|
    internal_url = ENV["url"].gsub("{iteration}", sprintf("%.2d", (iteration + 1)))
    uri = URI(internal_url)

    raw_address_base = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    ) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request.basic_auth ENV["username"], ENV["password"]

      http.request request
    end

    puts "Read CSV from #{internal_url} at #{Time.now}"

    csv_contents = raw_address_base.body

    if ENV["url"].to_s.include?(".zip")
      Zip::InputStream.open(StringIO.new(csv_contents)) do |io|
        io.get_next_entry

        csv_contents = io.read

        puts "Unzipped folder and read first file at #{Time.now}"
      end
    end


    puts "Size of CSV is #{csv_contents.size}, read at #{Time.now}"

    next unless csv_contents.size.positive?

    csv_contents = CSV.parse(csv_contents)

    puts "Parsed CSV at #{Time.now}"

    csv_contents.each_slice(10_000) do |inserts|
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

      puts "Created array to insert at #{Time.now}"

      ActiveRecord::Base.connection.execute("INSERT INTO address_base_tmp VALUES " + query.join(", "))

      puts "Inserted batch at #{Time.now}"
    end

    puts "Inserted file #{iteration.to_s} out of #{iterations.to_s} at #{Time.now}"
  end

  number_of_rows = db.execute("SELECT COUNT(uprn) AS number_of_addresses FROM address_base_tmp").first["number_of_addresses"]

  puts "Results batched and added to new table, number of results in table #{number_of_rows} at #{Time.now}"

  if number_of_rows == ENV["expected_number_of_rows"].to_i
    db.rename_table :address_base, :address_base_legacy

    puts "Renamed old address base at #{Time.now}"

    db.rename_table :address_base_tmp, :address_base

    puts "Put new address base table in place at #{Time.now}"

    db.drop_table :address_base_legacy

    puts "Dropped old address base table at #{Time.now}"

    db.execute("CREATE INDEX index_address_base_on_postcode ON address_base (postcode)")

    puts "Create address base postcode index at #{Time.now}"
  else
    puts "Number of addresses to import doesn't match, you said #{ENV['expected_number_of_rows']} and we found #{number_of_rows}"
  end
rescue StandardError => e
  puts "Error importing AddressBase: #{e}"
end
