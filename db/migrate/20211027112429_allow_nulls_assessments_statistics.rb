class AllowNullsAssessmentsStatistics < ActiveRecord::Migration[6.1]
  def change
    change_column_null :assessment_statistics, :rating_average, null: true
    change_column_null :assessment_statistics, :transaction_type, null: true
  end
end
