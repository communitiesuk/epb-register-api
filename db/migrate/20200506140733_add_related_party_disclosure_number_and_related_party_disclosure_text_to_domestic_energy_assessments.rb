class AddRelatedPartyDisclosureNumberAndRelatedPartyDisclosureTextToDomesticEnergyAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments,
               :related_party_disclosure_number,
               :integer
    add_column :domestic_energy_assessments,
               :related_party_disclosure_text,
               :string
  end
end
