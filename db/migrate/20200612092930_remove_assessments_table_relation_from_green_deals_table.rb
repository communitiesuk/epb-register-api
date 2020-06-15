class RemoveAssessmentsTableRelationFromGreenDealsTable < ActiveRecord::Migration[
  6.0
]
  def change
    remove_foreign_key :green_deal_plans, :assessments
  end
end
