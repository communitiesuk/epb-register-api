class AddIndexesToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_index :assessments, :type_of_assessment
    add_index :assessments, :cancelled_at
    add_index :assessments, :not_for_issue_at
  end
end
