class AddPrimaryKeyToGreenDealTable < ActiveRecord::Migration[6.0]
  def change
    execute("ALTER TABLE green_deal_plans ADD PRIMARY KEY (green_deal_plan_id)")
  end
end
