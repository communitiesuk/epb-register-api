class AddStatusColumnsToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :cancelled_at, :datetime
    add_column :assessments, :not_for_issue_at, :datetime
  end
end
