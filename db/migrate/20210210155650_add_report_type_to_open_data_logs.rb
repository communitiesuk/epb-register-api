class AddReportTypeToOpenDataLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :open_data_logs, :report_type, :string
  end
end
