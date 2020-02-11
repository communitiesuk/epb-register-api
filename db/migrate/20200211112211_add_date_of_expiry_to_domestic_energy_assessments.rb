class AddDateOfExpiryToDomesticEnergyAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments, :date_of_expiry, :datetime
  end
end
