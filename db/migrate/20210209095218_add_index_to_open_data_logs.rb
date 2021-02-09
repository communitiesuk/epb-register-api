class AddIndexToOpenDataLogs < ActiveRecord::Migration[6.1]
  def change
    add_index :open_data_logs, :assessment_id
    add_index :open_data_logs, :task_id
  end
end
