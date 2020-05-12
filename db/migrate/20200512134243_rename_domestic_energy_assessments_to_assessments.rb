class RenameDomesticEnergyAssessmentsToAssessments < ActiveRecord::Migration[6.0]
  def change
    rename_table :domestic_energy_assessments, :assessments
  end
end
