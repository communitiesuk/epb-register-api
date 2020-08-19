class RemoveInsulationFromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :impact_of_loft_insulation, :integer
    remove_column :assessments, :impact_of_cavity_insulation, :integer
    remove_column :assessments, :impact_of_solid_wall_insulation, :integer
  end
end
