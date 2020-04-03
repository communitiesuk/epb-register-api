class AlterEnergyAssessmentsValuesThatShouldBeFloats < ActiveRecord::Migration[6.0]
  def change
    change_column :domestic_energy_assessments, :total_floor_area, :decimal
    change_column :domestic_energy_assessments, :current_space_heating_demand, :decimal
    change_column :domestic_energy_assessments, :current_water_heating_demand, :decimal
  end
end
