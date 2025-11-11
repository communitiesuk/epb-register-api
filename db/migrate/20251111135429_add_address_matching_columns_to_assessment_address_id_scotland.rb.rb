class AddAddressMatchingColumnsToAssessmentAddressIdScotland < ActiveRecord::Migration[8.0]
  def change
    add_column "scotland.assessments_address_id", :matched_address_id, :string
    add_column "scotland.assessments_address_id", :matched_confidence, :float
  end

  def down
    remove_column "scotland.assessments_address_id", :matched_address_id
    remove_column "scotland.assessments_address_id", :matched_confidence
  end
end
