class InsertCountries < ActiveRecord::Migration[7.1]
  def up
    insert_sql = <<-SQL
       INSERT INTO countries(country_code, country_name, address_base_country_code)
                VALUES   ('', 'England and Scotland', '["E", "S"]'::jsonb),
                          ('', 'Channel Islands', '["L"]'::jsonb)
    SQL

    execute(insert_sql)
  end
end
