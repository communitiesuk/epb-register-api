class AddCurrentAndPotentialRatingsToDomesticEnergyAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments, :current_energy_efficiency_rating, :smallint, null: false
    add_column :domestic_energy_assessments, :potential_energy_efficiency_rating, :smallint, null: false
  end
end
