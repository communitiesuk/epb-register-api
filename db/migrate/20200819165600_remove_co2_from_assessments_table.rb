class RemoveCo2FromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :current_carbon_emission, :decimal
    remove_column :assessments, :potential_carbon_emission, :decimal
  end
end
