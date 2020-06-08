class RemoveGdpTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :gdp_charges
    drop_table :gdp_fuel_savings
    drop_table :gdp_measures
  end
end
