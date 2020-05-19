class RemoveRelatedPartyDisclosureNumberFromAssessors < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessors, :related_party_disclosure_number
  end
end
