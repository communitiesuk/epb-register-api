class AddForeignKeysToGreenDealAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :green_deal_assessments,
                    :assessments,
                    column: :assessment_id,
                    primary_key: :assessment_id,
                    name: "fk_assessment_id_assessments"
    add_foreign_key :green_deal_assessments,
                    :green_deal_plans,
                    column: :green_deal_plan_id,
                    primary_key: :green_deal_plan_id,
                    name: "fk_green_deal_plan_id_green_deal_plans"
  end
end
