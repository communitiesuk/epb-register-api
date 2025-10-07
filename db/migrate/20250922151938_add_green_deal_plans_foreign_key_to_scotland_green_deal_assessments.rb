class AddGreenDealPlansForeignKeyToScotlandGreenDealAssessments < ActiveRecord::Migration[8.0]
  def change
    add_index "scotland.green_deal_plans", :green_deal_plan_id, unique: true

    add_foreign_key "scotland.green_deal_assessments",
                    "scotland.green_deal_plans",
                    column: :green_deal_plan_id, primary_key: :green_deal_plan_id
  end
end
