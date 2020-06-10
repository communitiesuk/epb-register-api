class AddGreenDealPlanId < ActiveRecord::Migration[6.0]
  def change
    add_column :green_deal_plans, :green_deal_plan_id, :string
  end
end
