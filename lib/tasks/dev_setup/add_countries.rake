namespace :dev_data do
  desc "Insert countries into database"

  task :add_countries do
    Tasks::TaskHelpers.quit_if_production
    ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE countries RESTART IDENTITY CASCADE", "SQL")

    insert_sql = <<-SQL
            INSERT INTO countries(country_code, country_name, address_base_country_code)
            VALUES ('ENG', 'England' ,'["E"]'::jsonb),
                   ('EAW', 'England and Wales', '["E", "W"]'::jsonb),
                     ('UKN', 'Unknown', '{}'::jsonb),
                    ('NIR', 'Northern Ireland', '["N"]'::jsonb),
                    ('SCT', 'Scotland', '["S"]'::jsonb),
            ('', 'Channel Islands', '["L"]'::jsonb),
                ('NR', 'Not Recorded', null),
                ('WAL', 'Wales', '["W"]'::jsonb)

    SQL
    ActiveRecord::Base.connection.exec_query(insert_sql, "SQL")
  end
end
