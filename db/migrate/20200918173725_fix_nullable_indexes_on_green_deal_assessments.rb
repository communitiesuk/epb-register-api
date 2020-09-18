class FixNullableIndexesOnGreenDealAssessments < ActiveRecord::Migration[6.0]
  def change
    change_column_null :green_deal_assessments, :green_deal_plan_id, false
    change_column_null :green_deal_assessments, :assessment_id, false

    add_index :green_deal_assessments, %i[green_deal_plan_id assessment_id], { unique: true, name: "index_green_deal_assessments_on_plan_id_and_assessment_id" }
  end
end
