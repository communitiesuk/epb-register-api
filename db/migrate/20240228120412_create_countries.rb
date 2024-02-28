class CreateCountries < ActiveRecord::Migration[7.1]
  def up
    create_table :countries, primary_key: :country_id do |t|
      t.string :country_code
      t.string :country_name
    end

    insert_sql = <<-SQL
            INSERT INTO countries(country_code, country_name)
            VALUES ('ENG', 'England'),
                   ('WAL', 'Wales'),
                   ('NIR', 'Northern Ireland'),
                   ('EAW', 'England and Wales')
    SQL

    execute(insert_sql)
  end

  def down
    drop_table :countries, if_exists: true
  end
end
