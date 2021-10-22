class CreateAssessmentStatisitcs < ActiveRecord::Migration[6.1]
  def change
    create_table :assessment_statistics, primary_key: nil do |t|
      t.integer :assessments_count, null: false
      t.string :assessment_type, null: false
      t.float  :rating_average, null: false
      t.datetime :day_date, null: false
      t.integer :scheme_id, null: false
      t.integer :transaction_type, null: false
    end
  end
end
