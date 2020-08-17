class RemoveSavingsTypeFromAssessments < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :lighting_cost_current
    remove_column :assessments, :lighting_cost_potential
    remove_column :assessments, :heating_cost_current
    remove_column :assessments, :heating_cost_potential
    remove_column :assessments, :hot_water_cost_current
    remove_column :assessments, :hot_water_cost_potential
  end
end
