class AddFuelSavingsDataToGdpFuelSavingsTable < ActiveRecord::Migration[6.0]
  def change
    add_column :gdp_charges, :fuel_code, :string
    add_column :gdp_charges, :fuel_saving, :integer
    add_column :gdp_charges, :standing_charge_fraction, :decimal
  end
end
