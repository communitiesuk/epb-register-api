class CreateGreenDealFuelPriceDataTable < ActiveRecord::Migration[6.0]
  def change
    create_table :green_deal_fuel_price_data, primary_key: :fuel_heat_source, id: false do |t|
      t.integer :fuel_heat_source
      t.column :standing_charge, :decimal, precision: 5, scale: 2
      t.column :fuel_price, :decimal, precision: 10, scale: 2
    end
  end
end
