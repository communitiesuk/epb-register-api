class AddHashedAssessmentIdToAssessments < ActiveRecord::Migration[7.0]
  def change
    add_column :assessments, :hashed_assessment_id, :string
  end
end
