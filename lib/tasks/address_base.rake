require "openssl"
require "csv"

desc "Truncate AddressBase data"

task :truncate_address_base do
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE address_base RESTART IDENTITY CASCADE")
end

desc "Import AddressBase data"

task :import_green_deal_plans do
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

  address_base = CSV.parse(raw_address_base.body)

  ActiveRecord::Base.transaction do
    address_base.each do |row|
      puts row
      query = "INSERT INTO
            address_base
            VALUES (
                '#{ActiveRecord::Base.sanitize_sql(row[0])}',
                '#{ActiveRecord::Base.sanitize_sql(row[64])}',
                '#{ActiveRecord::Base.sanitize_sql(row[34])}',
                '#{ActiveRecord::Base.sanitize_sql([row[28], row[24], row[25], row[26], row[27]].reject(&:empty?).join(" "))}',
                '#{ActiveRecord::Base.sanitize_sql([row[34], row[30], row[31], row[32], row[33]].reject(&:empty?).join(" "))}',
                '#{ActiveRecord::Base.sanitize_sql(row[49])}',
                '#{ActiveRecord::Base.sanitize_sql(row[60])}'
            )"
      ActiveRecord::Base.connection.execute(query)
    end
  end
end
