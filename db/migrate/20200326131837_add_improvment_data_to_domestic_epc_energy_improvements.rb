class AddImprovmentDataToDomesticEpcEnergyImprovements < ActiveRecord::Migration[
  6.0
]
  def change
    add_column :domestic_epc_energy_improvements, :improvement_code, :string
    add_column :domestic_epc_energy_improvements, :indicative_cost, :string
    add_column :domestic_epc_energy_improvements, :typical_saving, :float
    add_column :domestic_epc_energy_improvements, :improvement_category, :string
    add_column :domestic_epc_energy_improvements, :improvement_type, :string
    add_column :domestic_epc_energy_improvements,
               :energy_performance_rating,
               :string
    add_column :domestic_epc_energy_improvements,
               :environmental_impact_rating,
               :string
    add_column :domestic_epc_energy_improvements,
               :green_deal_category_code,
               :string
  end
end
