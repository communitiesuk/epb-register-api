class CreateGreenDealAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :green_deal_assessments, { id: false } do |t|
      t.string :green_deal_plan_id
      t.string :assessment_id
    end
  end
end
