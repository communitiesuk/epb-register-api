class RemovePotentialRatingFromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :potential_energy_efficiency_rating, :integer
  end
end
