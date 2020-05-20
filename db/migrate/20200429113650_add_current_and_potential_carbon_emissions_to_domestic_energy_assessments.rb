class AddCurrentAndPotentialCarbonEmissionsToDomesticEnergyAssessments < ActiveRecord::Migration[
  6.0
]
  def change
    add_column :domestic_energy_assessments,
               :current_carbon_emission,
               :decimal,
               null: false,
               default: 0
    add_column :domestic_energy_assessments,
               :potential_carbon_emission,
               :decimal,
               null: false,
               default: 0
  end
end
