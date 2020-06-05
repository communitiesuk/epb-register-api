class AddFuelSavingsDataToGdpFuelSavingsTable < ActiveRecord::Migration[6.0]
  def change
    add_column :gdp_fuel_savings, :fuel_code, :string
    add_column :gdp_fuel_savings, :fuel_saving, :integer
    add_column :gdp_fuel_savings, :standing_charge_fraction, :decimal
  end
end
