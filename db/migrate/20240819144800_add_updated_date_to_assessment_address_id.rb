class AddUpdatedDateToAssessmentAddressId < ActiveRecord::Migration[7.2]
  def change
    add_column :assessments_address_id, :address_updated_at, :datetime
  end
end
