class AddAssessmentsTableRelationToGreenDealsTable < ActiveRecord::Migration[
  6.0
]
  def change
    add_column :green_deal_plans, :assessment_id, :string
    add_foreign_key :green_deal_plans,
                    :assessments,
                    column: :assessment_id, primary_key: :assessment_id
  end
end
