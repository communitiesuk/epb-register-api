class AddMeasuresDataToGdpMeasuresDataTable < ActiveRecord::Migration[6.0]
  def change
    add_column :gdp_measures, :measure_type, :string
    add_column :gdp_measures, :product, :string
    add_column :gdp_measures, :repaid_date, :datetime
  end
end
