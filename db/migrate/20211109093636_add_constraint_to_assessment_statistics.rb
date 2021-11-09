class AddConstraintToAssessmentStatistics < ActiveRecord::Migration[6.1]
  def change
    add_index :assessment_statistics, %i[assessment_type day_date transaction_type],
              unique: true,
              name: "index_assessment_statistics_unique_group"
  end
end
