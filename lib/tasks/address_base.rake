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

  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS address_base_temp")
  ActiveRecord::Base.connection.execute("CREATE TABLE IF NOT EXISTS address_base_temp (
   uprn VARCHAR (255),
   postcode VARCHAR (255),
   address_line1 VARCHAR (255),
   address_line2 VARCHAR (255),
   address_line3 VARCHAR (255),
   address_line4 VARCHAR (255),
   town VARCHAR (255)
);")

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

    csv_contents = raw_address_base.body

    if ENV["url"].to_s.include?(".zip")
      Zip::InputStream.open(StringIO.new(csv_contents)) do |io|
        io.get_next_entry

        csv_contents = io.read
      end
    end

    next unless csv_contents.size.positive?

    csv_contents = CSV.parse(csv_contents)
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
        lines.push(row[61])

        # If the administrative area name is desired, and if it is not a duplicate of the town name, if may optionally be included on a separate line beneath the town name.
        if row[62] != row[61]
          lines.push(row[62])
        end

        lines = lines.reject(&:blank?)

        # Finally, the postcode locator, if present, should be inserted on the final line of the address.
        postcode = row[64]

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

      ActiveRecord::Base.connection.execute("INSERT INTO address_base_temp VALUES " + query.join(", "))
    end

    ActiveRecord::Base.connection.execute("INSERT INTO address_base SELECT * FROM address_base_temp ON CONFLICT DO NOTHING")
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE address_base_temp")
  end

  ActiveRecord::Base.connection.execute("DROP TABLE address_base_temp")
end
