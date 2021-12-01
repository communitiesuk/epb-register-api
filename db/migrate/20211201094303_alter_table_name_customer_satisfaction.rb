class AlterTableNameCustomerSatisfaction < ActiveRecord::Migration[6.1]
  def change
    rename_table :customer_satisfaction, :user_satisfaction
  end
end
