class RemoveTenureFromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :tenure, :string
  end
end
