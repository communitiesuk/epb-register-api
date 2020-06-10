class AlterAssessmentsTableAddAddressIdIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :assessments, :address_id
  end
end
