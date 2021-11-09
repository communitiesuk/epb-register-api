class AddIndexesAssessmentStatistics < ActiveRecord::Migration[6.1]
  def change
    add_index :assessment_statistics, :day_date
    add_index :assessment_statistics, :assessments_count
    add_index :assessment_statistics, :rating_average
  end
end
