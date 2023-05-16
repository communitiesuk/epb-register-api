class AddMissingPrimaryKeys < ActiveRecord::Migration[7.0]
  def up
    # add pk to address_base_versions
    execute "DELETE FROM address_base_versions abv WHERE EXISTS (SELECT FROM address_base_versions WHERE version_number = abv.version_number AND ctid < abv.ctid)"
    execute "ALTER TABLE address_base_versions ADD PRIMARY KEY (version_number)"

    # add pk to green_deal_assessments
    execute "ALTER TABLE green_deal_assessments ADD PRIMARY KEY (green_deal_plan_id, assessment_id)"

    # add pk for green_deal_fuel_code_map (arbitrary id)
    change_table :green_deal_fuel_code_map do |t|
      t.primary_key :id
    end

    # add pk for green_deal_fuel_price_data (arbitrary id)
    change_table :green_deal_fuel_price_data do |t|
      t.primary_key :id
    end
  end

  def down
    execute "ALTER TABLE green_deal_fuel_price_data DROP CONSTRAINT green_deal_fuel_price_data_pkey"
    execute "ALTER TABLE green_deal_fuel_price_data DROP COLUMN id"

    execute "ALTER TABLE green_deal_fuel_code_map DROP CONSTRAINT green_deal_fuel_code_map_pkey"
    execute "ALTER TABLE green_deal_fuel_code_map DROP COLUMN id"

    execute "ALTER TABLE green_deal_assessments DROP CONSTRAINT green_deal_assessments_pkey"

    execute "ALTER TABLE address_base_versions DROP CONSTRAINT address_base_versions_pkey"
  end
end
