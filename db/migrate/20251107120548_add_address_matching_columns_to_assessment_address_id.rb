class AddAddressMatchingColumnsToAssessmentAddressId < ActiveRecord::Migration[8.0]
  def change
    add_column :assessments_address_id, :matched_address_id, :string
    add_column :assessments_address_id, :matched_confidence, :float
  end

  def down
    remove_column :assessments_address_id, :matched_address_id
    remove_column :assessments_address_id, :matched_confidence
  end
end
