class RemoveAssessmentIdFromGreenDealTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :green_deal_plans, :assessment_id
  end
end
