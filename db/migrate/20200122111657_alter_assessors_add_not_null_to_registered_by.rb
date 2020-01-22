class AlterAssessorsAddNotNullToRegisteredBy < ActiveRecord::Migration[6.0]
  def change
     change_column_null :assessors, :registered_by, false
  end
end
