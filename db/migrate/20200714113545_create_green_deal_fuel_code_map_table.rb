class CreateGreenDealFuelCodeMapTable < ActiveRecord::Migration[6.0]
  def change
    create_table :green_deal_fuel_code_map,
                 primary_key: :fuel_code, id: false do |t|
      t.integer :fuel_code
      t.integer :fuel_category
      t.integer :fuel_heat_source
    end
  end
end
