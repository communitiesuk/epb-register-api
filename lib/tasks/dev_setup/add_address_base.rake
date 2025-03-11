namespace :dev_data do
  desc "Insert address base data into database"

  task :add_address_base do
    Tasks::TaskHelpers.quit_if_production
    ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE address_base RESTART IDENTITY CASCADE", "SQL")
    AddAddressBaseTaskHelper.add_address_base uprn: "100020003000", postcode: "AL1C 2DE", country_code: "E"
    AddAddressBaseTaskHelper.add_address_base uprn: "100020004000", postcode: "SW1A 2AA", country_code: "E"
    AddAddressBaseTaskHelper.add_address_base uprn: "100020005000", postcode: "SW1 0AA", country_code: "E"
    AddAddressBaseTaskHelper.add_address_base uprn: "1000200099",   postcode: "SW1 0AA", country_code: "E"
    AddAddressBaseTaskHelper.add_address_base uprn: "199999999999", postcode: "BT1 2DE", country_code: "N"
    AddAddressBaseTaskHelper.add_address_base uprn: "999999999999", postcode: "XX1 1XX", country_code: "E"
  end
end

class AddAddressBaseTaskHelper
  def self.add_address_base(uprn:, postcode: nil, country_code: nil)
    ActiveRecord::Base.connection.exec_query(
      "INSERT INTO address_base (uprn, postcode, country_code) VALUES($1, $2, $3) ON CONFLICT DO NOTHING",
      "sql",
      [
        ActiveRecord::Relation::QueryAttribute.new("uprn", uprn, ActiveRecord::Type::String.new),
        ActiveRecord::Relation::QueryAttribute.new("postcode", postcode, ActiveRecord::Type::String.new),
        ActiveRecord::Relation::QueryAttribute.new("country_code", country_code, ActiveRecord::Type::String.new),
      ],
    )
  end
end
