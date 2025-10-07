class RemoveIncorrectForeignKeysFromScotlandTableContinued < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key "scotland.assessments_country_ids", name: "fks_assessments_country_ids_countries"
    remove_foreign_key "scotland.assessments", name: "fk_rails_4307e1668a"
    remove_foreign_key "scotland.green_deal_assessments", name: "fk_assessment_id_assessments"
    remove_foreign_key "scotland.green_deal_assessments", name: "fk_green_deal_plan_id_green_deal_plans"
  end
end
