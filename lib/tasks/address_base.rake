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
    raw_address_base = nil
    io.get_next_entry

    csv_contents = io.read

    if csv_contents.positive?
      csv_contents = CSV.parse(csv_contents)
      csv_contents.each do |row|
        query = "INSERT INTO
            address_base
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7
            )"
        ActiveRecord::Base.connection.exec_query(
          query,
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "uprn",
              row[0],
              ActiveRecord::Type::String.new,
            ),
            ActiveRecord::Relation::QueryAttribute.new(
              "postcode",
              row[64],
              ActiveRecord::Type::String.new,
            ),
            ActiveRecord::Relation::QueryAttribute.new(
              "rrn",
              row[34],
              ActiveRecord::Type::String.new,
            ),
            ActiveRecord::Relation::QueryAttribute.new(
              "addressline_1",
              [row[28], row[24], row[25], row[26], row[27]].reject(&:blank?).join(" "),
              ActiveRecord::Type::String.new,
            ),
            ActiveRecord::Relation::QueryAttribute.new(
              "addressline_2",
              [row[34], row[30], row[31], row[32], row[33]].reject(&:blank?).join(" "),
              ActiveRecord::Type::String.new,
            ),
            ActiveRecord::Relation::QueryAttribute.new(
              "addressline_3",
              row[49],
              ActiveRecord::Type::String.new,
            ),
            ActiveRecord::Relation::QueryAttribute.new(
              "town",
              row[60],
              ActiveRecord::Type::String.new,
            ),
          ],
        )
      end
    end
  end
end
