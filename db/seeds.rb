require "zeitwerk"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib/")
loader.setup

fuel_code_map = [
  { fuel_code: 26, fuel_category: 1, fuel_heat_source: 1 },
  { fuel_code: 27, fuel_category: 3, fuel_heat_source: 2 },
  { fuel_code: 3, fuel_category: 3, fuel_heat_source: 3 },
  { fuel_code: 17, fuel_category: 1, fuel_heat_source: 9 },
  { fuel_code: 28, fuel_category: 3, fuel_heat_source: 4 },
  { fuel_code: 34, fuel_category: 3, fuel_heat_source: 71 },
  { fuel_code: 35, fuel_category: 3, fuel_heat_source: 72 },
  { fuel_code: 36, fuel_category: 3, fuel_heat_source: 73 },
  { fuel_code: 37, fuel_category: 3, fuel_heat_source: 74 },
  { fuel_code: 18, fuel_category: 3, fuel_heat_source: 75 },
  { fuel_code: 19, fuel_category: 3, fuel_heat_source: 76 },
  { fuel_code: 33, fuel_category: 3, fuel_heat_source: 11 },
  { fuel_code: 5, fuel_category: 3, fuel_heat_source: 15 },
  { fuel_code: 15, fuel_category: 3, fuel_heat_source: 12 },
  { fuel_code: 6, fuel_category: 3, fuel_heat_source: 20 },
  { fuel_code: 16, fuel_category: 3, fuel_heat_source: 22 },
  { fuel_code: 7, fuel_category: 3, fuel_heat_source: 23 },
  { fuel_code: 8, fuel_category: 3, fuel_heat_source: 21 },
  { fuel_code: 9, fuel_category: 3, fuel_heat_source: 10 },
  { fuel_code: 39, fuel_category: 2, fuel_heat_source: 30 },
  { fuel_code: 40, fuel_category: 2, fuel_heat_source: 32 },
  { fuel_code: 41, fuel_category: 2, fuel_heat_source: 31 },
  { fuel_code: 44, fuel_category: 2, fuel_heat_source: 34 },
  { fuel_code: 45, fuel_category: 2, fuel_heat_source: 33 },
  { fuel_code: 42, fuel_category: 2, fuel_heat_source: 35 },
  { fuel_code: 38, fuel_category: 3, fuel_heat_source: 47 },
  { fuel_code: 43, fuel_category: 3, fuel_heat_source: 48 },
]

sql = <<~SQL
  INSERT INTO green_deal_fuel_code_map (fuel_code, fuel_category,fuel_heat_source ) VALUES
SQL

fuel_code_map.each do |mapping|
  sql <<
    "(#{mapping[:fuel_code]}, #{mapping[:fuel_category]}, #{
      mapping[:fuel_heat_source]
    }),"
end

sql = sql.delete_suffix ","

ActiveRecord::Base.connection.execute sql
