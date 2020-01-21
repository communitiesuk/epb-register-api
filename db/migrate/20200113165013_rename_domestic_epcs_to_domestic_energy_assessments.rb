class RenameDomesticEpcsToDomesticEnergyAssessments < ActiveRecord::Migration[
  6.0
]
  def self.up
    rename_table :domestic_epcs, :domestic_energy_assessments
  end

  def self.down
    rename_table :domestic_energy_assessments, :domestic_epcs
  end
end
