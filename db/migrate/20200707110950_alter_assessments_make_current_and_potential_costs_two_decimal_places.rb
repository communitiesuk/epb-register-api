class AlterAssessmentsMakeCurrentAndPotentialCostsTwoDecimalPlaces < ActiveRecord::Migration[6.0]
  def change
    change_column :assessments, :lighting_cost_current, :decimal, precision: 10, scale: 2
    change_column :assessments, :heating_cost_current, :decimal, precision: 10, scale: 2
    change_column :assessments, :hot_water_cost_current, :decimal, precision: 10, scale: 2
    change_column :assessments, :lighting_cost_potential, :decimal, precision: 10, scale: 2
    change_column :assessments, :heating_cost_potential, :decimal, precision: 10, scale: 2
    change_column :assessments, :hot_water_cost_potential, :decimal, precision: 10, scale: 2
  end
end
