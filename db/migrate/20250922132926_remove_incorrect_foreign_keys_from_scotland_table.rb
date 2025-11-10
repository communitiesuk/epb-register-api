class RemoveIncorrectForeignKeysFromScotlandTable < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key "scotland.assessments_xml", "assessments"
    remove_foreign_key "scotland.green_deal_assessments", "assessments"
    remove_foreign_key "scotland.green_deal_assessments", "green_deal_plans"
  end
end
