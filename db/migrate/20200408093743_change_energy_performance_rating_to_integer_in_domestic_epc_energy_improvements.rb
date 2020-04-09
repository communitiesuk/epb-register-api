class ChangeEnergyPerformanceRatingToIntegerInDomesticEpcEnergyImprovements < ActiveRecord::Migration[
  6.0
]
  def change
    change_column :domestic_epc_energy_improvements,
                  :energy_performance_rating,
                  'integer USING CAST(energy_performance_rating AS integer)'
  end
end
