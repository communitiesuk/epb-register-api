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

  uri = URI(ENV["url"])

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

  ActiveRecord::Base.transaction do
    if csv_contents.size.positive?
      csv_contents = CSV.parse(csv_contents)
      csv_contents.each_slice(100) do |inserts|
        query = []
        inserts.map do |row|
          uprn = ActiveRecord::Base.connection.quote(row[0])
          postcode = ActiveRecord::Base.connection.quote(row[64])
          address_line1 = ActiveRecord::Base.connection.quote([row[28], row[24], row[25], row[26], row[27]].reject(&:blank?).join(" "))
          address_line2 = ActiveRecord::Base.connection.quote([row[34], row[30], row[31], row[32], row[33]].reject(&:blank?).join(" "))
          address_line3 = ActiveRecord::Base.connection.quote(row[49])
          address_line4 = ActiveRecord::Base.connection.quote(row[49])
          town = ActiveRecord::Base.connection.quote(row[60])

          query.push("(
                  #{uprn},
                  #{postcode},
                  #{address_line1},
                  #{address_line2},
                  #{address_line3},
                  #{address_line4},
                  #{town}
              )")
        end

        ActiveRecord::Base.connection.execute("INSERT INTO address_base VALUES " + query.join(", "))
      end
    end
  end
end
