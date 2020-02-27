class AlterAssessorsAddNotNullToRequiredFields < ActiveRecord::Migration[6.0]
  def change
    change_column_null :assessors, :first_name, false
    change_column_null :assessors, :last_name, false
    change_column_null :assessors, :date_of_birth, false
  end
end
