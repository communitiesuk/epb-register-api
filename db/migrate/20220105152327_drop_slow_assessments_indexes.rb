class DropSlowAssessmentsIndexes < ActiveRecord::Migration[6.1]
  def up
    remove_index :assessments, :cancelled_at
    remove_index :assessments, :not_for_issue_at
  end

  def down
    add_index :assessments, :cancelled_at
    add_index :assessments, :not_for_issue_at
  end
end
