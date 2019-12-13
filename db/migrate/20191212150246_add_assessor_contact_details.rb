class AddAssessorContactDetails < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :telephone_number, :string
    add_column :assessors, :email, :string
  end
end
