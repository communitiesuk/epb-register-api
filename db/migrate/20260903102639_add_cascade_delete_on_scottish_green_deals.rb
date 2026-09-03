class AddCascadeDeleteOnScottishGreenDeals < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key "scotland.green_deal_assessments",
                       "green_deal_plans",
                       column: :green_deal_plan_id,
                       primary_key: :green_deal_plan_id,
                       name: "fk_public_green_deal_plans_scotland_assessments"
    add_foreign_key "scotland.green_deal_assessments",
                    "green_deal_plans",
                    column: :green_deal_plan_id,
                    primary_key: :green_deal_plan_id,
                    on_delete: :cascade,
                    name: "fk_scotland_green_deal_plan_id_green_deal_plans"
  end
end
