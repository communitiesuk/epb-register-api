class AddChargesDataToGdpChargesDataTable < ActiveRecord::Migration[6.0]
  def change
    add_column :gdp_charges, :start_date, :datetime
    add_column :gdp_charges, :end_date, :datetime
    add_column :gdp_charges, :daily_charge, :decimal
  end
end
