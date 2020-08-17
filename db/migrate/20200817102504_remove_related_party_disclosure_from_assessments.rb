class RemoveRelatedPartyDisclosureFromAssessments < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :related_party_disclosure_number
    remove_column :assessments, :related_party_disclosure_text
  end
end
