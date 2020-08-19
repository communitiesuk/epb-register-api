class RemoveDwellingTypeFromAssessments < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :dwelling_type
  end
end
