class AddIndexesToAssessmentsForAddressSearch < ActiveRecord::Migration[6.0]
  def change
    add_index :assessments, :address_line1
    add_index :assessments, :address_line2
  end
end
