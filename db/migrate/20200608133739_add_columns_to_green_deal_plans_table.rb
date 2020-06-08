class AddColumnsToGreenDealPlansTable < ActiveRecord::Migration[6.0]
  def change
    add_column :green_deal_plans, :measures, :jsonb, null: false, default: "{}"

    add_column :green_deal_plans, :charges, :jsonb, null: false, default: "{}"

    add_column :green_deal_plans, :savings, :jsonb, null: false, default: "{}"
  end
end
