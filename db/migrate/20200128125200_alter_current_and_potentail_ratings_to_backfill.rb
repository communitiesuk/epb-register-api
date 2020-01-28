class AlterCurrentAndPotentailRatingsToBackfill < ActiveRecord::Migration[6.0]
  def change
    change_column :domestic_energy_assessments, :current_energy_efficiency_rating, :smallint, null: false, default: 1
    change_column :domestic_energy_assessments, :potential_energy_efficiency_rating, :smallint, null: false, default: 2
  end
end
