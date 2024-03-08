class AlterCountries < ActiveRecord::Migration[7.1]
  def up
    add_column :countries, :address_base_country_code, :jsonb, null: true, default: "{}"

    insert_sql = <<-SQL
                INSERT INTO countries(country_code, country_name)
                VALUES ('SCT', 'Scotland'),
                  ('IOM', 'Isle of Man'),
                  ('NR', 'Not Recorded'),
                  ('UKN', 'Unknown')

    SQL

    execute(insert_sql)
    execute("UPDATE countries SET country_code = 'WLS' WHERE country_code = 'WAL'")

    update_sql = <<~SQL
        UPDATE countries SET address_base_country_code = CASE
         WHEN country_code = 'ENG' THEN '["E"]'::jsonb
         WHEN country_code = 'NIR' THEN '["N"]'::jsonb
         WHEN country_code = 'WLS' THEN '["W"]'::jsonb
          WHEN country_code = 'EAW' THEN '["E", "W"]'::jsonb
          WHEN country_code = 'SCT' THEN '["S"]'::jsonb
          WHEN country_code = 'IOM' THEN '["M"]'::jsonb
      END
    SQL

    execute(update_sql)
  end
end
