class RemoveFloorAreaFromAssessments < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :total_floor_area
  end
end
