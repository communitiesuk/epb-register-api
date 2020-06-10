class RemovePrimaryKeyFromGreenDealTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :green_deal_plans, :green_deal_plan_id
  end
end
