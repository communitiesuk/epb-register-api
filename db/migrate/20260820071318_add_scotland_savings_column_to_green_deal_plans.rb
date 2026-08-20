class AddScotlandSavingsColumnToGreenDealPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :green_deal_plans, :savings_scotland, :jsonb, null: false, default: "[]"
  end

  def down
    remove_column :green_deal_plans, :savings_scotland, :jsonb
  end
end
