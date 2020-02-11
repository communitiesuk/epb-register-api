class AddPostcodeToDomesticEnergyAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments, :postcode, :string
  end
end
