class CreateOpenDataLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :open_data_logs, primary_key: nil do |t|
      t.string :assessment_id, null: false
      t.string :assessment_hash_id, null: false
      t.datetime :created_at, null: false
      t.integer  :task_id, null: false
    end
  end
end
