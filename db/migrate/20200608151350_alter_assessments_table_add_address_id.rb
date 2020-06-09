class AlterAssessmentsTableAddAddressId < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :address_id, :string
  end
end
