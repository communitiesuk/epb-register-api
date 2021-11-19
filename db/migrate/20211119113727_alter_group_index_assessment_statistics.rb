class AlterGroupIndexAssessmentStatistics < ActiveRecord::Migration[6.1]
  def change
    remove_index :assessment_statistics, name: "index_assessment_statistics_unique_group"

    add_index :assessment_statistics, %i[assessment_type day_date transaction_type country],
              unique: true,
              name: "index_assessment_statistics_unique_group"
  end
end
