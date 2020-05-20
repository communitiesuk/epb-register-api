class AddOptOutToDomesticEnergyAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments,
               :opt_out,
               :boolean,
               default: false,
               null: false
  end
end
