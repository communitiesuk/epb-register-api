class RemoveAssessmentHashIdFromOpenDataLogs1 < ActiveRecord::Migration[6.1]
  def change
    remove_column :open_data_logs, :assessment_hash_id, :string
  end
end
