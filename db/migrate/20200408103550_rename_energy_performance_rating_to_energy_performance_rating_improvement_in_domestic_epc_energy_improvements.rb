class RenameEnergyPerformanceRatingToEnergyPerformanceRatingImprovementInDomesticEpcEnergyImprovements < ActiveRecord::Migration[6.0]
  def change
    rename_column :domestic_epc_energy_improvements, :energy_performance_rating, :energy_performance_rating_improvement
  end
end
