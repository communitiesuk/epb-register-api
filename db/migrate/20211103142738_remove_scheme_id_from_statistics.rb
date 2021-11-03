class RemoveSchemeIdFromStatistics < ActiveRecord::Migration[6.1]
  def change
    remove_column :assessment_statistics, :scheme_id
  end
end
