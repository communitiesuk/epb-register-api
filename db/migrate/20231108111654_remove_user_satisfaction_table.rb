class RemoveUserSatisfactionTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :user_satisfaction
  end
end
