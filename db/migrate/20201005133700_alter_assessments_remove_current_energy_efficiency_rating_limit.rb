class AlterAssessmentsRemoveCurrentEnergyEfficiencyRatingLimit < ActiveRecord::Migration[6.0]
  def up
    change_column :assessments, :current_energy_efficiency_rating, :integer, limit: nil
  end

  def down
    change_column :assessments, :current_energy_efficiency_rating, :integer, limit: 2
  end
end
