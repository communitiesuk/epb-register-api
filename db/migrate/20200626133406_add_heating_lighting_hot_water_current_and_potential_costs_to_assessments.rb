class AddHeatingLightingHotWaterCurrentAndPotentialCostsToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :lighting_cost_current, :decimal
    add_column :assessments, :heating_cost_current, :decimal
    add_column :assessments, :hot_water_cost_current, :decimal
    add_column :assessments, :lighting_cost_potential, :decimal
    add_column :assessments, :heating_cost_potential, :decimal
    add_column :assessments, :hot_water_cost_potential, :decimal
  end
end
