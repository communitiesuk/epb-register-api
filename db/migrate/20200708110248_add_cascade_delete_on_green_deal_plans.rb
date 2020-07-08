class AddCascadeDeleteOnGreenDealPlans < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :green_deal_assessments, :green_deal_plans
    add_foreign_key :green_deal_assessments,
                    :green_deal_plans,
                    column: :green_deal_plan_id,
                    primary_key: :green_deal_plan_id,
                    on_delete: :cascade,
                    name: "fk_green_deal_plan_id_green_deal_plans"
  end
end
