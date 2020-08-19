class RemoveHeatingDemandFromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :current_space_heating_demand, :decimal
    remove_column :assessments, :current_water_heating_demand, :decimal
  end
end
