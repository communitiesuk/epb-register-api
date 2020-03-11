class AddHeatDemandDataToDomesticEnergyAssessments < ActiveRecord::Migration[
  6.0
]
  def change
    add_column :domestic_energy_assessments,
               :current_space_heating_demand,
               :integer
    add_column :domestic_energy_assessments,
               :current_water_heating_demand,
               :integer
    add_column :domestic_energy_assessments,
               :impact_of_loft_insulation,
               :integer
    add_column :domestic_energy_assessments,
               :impact_of_cavity_insulation,
               :integer
    add_column :domestic_energy_assessments,
               :impact_of_solid_wall_insulation,
               :integer
  end
end
