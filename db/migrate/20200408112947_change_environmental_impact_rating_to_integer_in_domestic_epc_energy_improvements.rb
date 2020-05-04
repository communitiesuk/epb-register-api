class ChangeEnvironmentalImpactRatingToIntegerInDomesticEpcEnergyImprovements < ActiveRecord::Migration[
  6.0
]
  def change
    change_column :domestic_epc_energy_improvements,
                  :environmental_impact_rating,
                  "integer USING CAST(environmental_impact_rating AS integer)"
  end
end
