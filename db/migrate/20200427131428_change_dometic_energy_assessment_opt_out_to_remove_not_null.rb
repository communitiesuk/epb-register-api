class ChangeDometicEnergyAssessmentOptOutToRemoveNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column :domestic_energy_assessments,
               :opt_out,
               :boolean,
               null: true
  end
end
