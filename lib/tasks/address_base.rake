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

  Zip::InputStream.open(StringIO.new(raw_address_base.body)) do |io|
    io.get_next_entry

    csv_contents = io.read

    if csv_contents.size > 0
      address_base = CSV.parse(csv_contents)
      address_base.each do |row|
        query = "INSERT INTO
            address_base
            VALUES (
                '#{ActiveRecord::Base.sanitize_sql(row[0])}',
                '#{ActiveRecord::Base.sanitize_sql(row[64])}',
                '#{ActiveRecord::Base.sanitize_sql(row[34])}',
                '#{ActiveRecord::Base.sanitize_sql([row[28], row[24], row[25], row[26], row[27]].reject(&:blank?).join(" "))}',
                '#{ActiveRecord::Base.sanitize_sql([row[34], row[30], row[31], row[32], row[33]].reject(&:blank?).join(" "))}',
                '#{ActiveRecord::Base.sanitize_sql(row[49])}',
                '#{ActiveRecord::Base.sanitize_sql(row[60])}'
            )"
        ActiveRecord::Base.connection.execute(query)
      end
    end
  end
end
