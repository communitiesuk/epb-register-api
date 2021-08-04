desc "Import up to date data for green deal fuel prices"

task :green_deal_update_fuel_data do
  raw_data = Net::HTTP.get URI "http://www.boilers.org.uk/data1/pcdf2012.dat"

  price_data = raw_data.scan(/^[\d],[\d]+,[\d]+,[\d]+\.[\d]+,[\d]{4}\/[\S]+\/[\d]+ [\d]{2}:[\d]{2}/mi)

  headers = %i[category heat_source standing_charge price date]

  price_data = price_data.map do |row|
    headers.zip(row.split(",")).to_h
  end

  ActiveRecord::Base.transaction do
    ActiveRecord::Base.connection.exec_query "DELETE FROM green_deal_fuel_price_data"

    price_data.each do |row|
      sql = <<-SQL
        INSERT INTO green_deal_fuel_price_data VALUES($1, $2, $3)
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "fuel_heat_source",
          row[:heat_source],
          ActiveRecord::Type::UnsignedInteger.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "standing_charge",
          row[:standing_charge],
          ActiveRecord::Type::Decimal.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "fuel_price",
          row[:price],
          ActiveRecord::Type::Decimal.new,
        ),
      ]

      ActiveRecord::Base.connection.exec_query sql, "SQL", binds
    end
  end
end
