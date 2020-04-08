class RenameEnvironmentalImpactRatingToEnvironmentalImpactRatingImprovementInDomesticEpcEnergyImprovements < ActiveRecord::Migration[6.0]
  def change
    rename_column :domestic_epc_energy_improvements, :environmental_impact_rating, :environmental_impact_rating_improvement
  end
end
