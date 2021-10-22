class AddCreatedAtIndexToAssessments < ActiveRecord::Migration[6.1]
  def change
    add_index :assessments, :created_at
  end
end
