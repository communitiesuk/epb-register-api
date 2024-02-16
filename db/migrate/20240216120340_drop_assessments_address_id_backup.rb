class DropAssessmentsAddressIdBackup < ActiveRecord::Migration[7.1]
  def change
    if table_exists?(:assessments_address_id_backup)
      drop_table :assessments_address_id_backup
    end
  end
end
