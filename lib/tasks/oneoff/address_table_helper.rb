module AddressTableHelper
  def self.create_backup
    db = ActiveRecord::Base.connection

    unless db.table_exists?(:assessments_address_id_backup)
      db.create_table :assessments_address_id_backup, primary_key: :assessment_id, id: :string do |t|
        t.string :address_id, index: true
        t.string :source
      end
      puts "[#{Time.now}] Created empty assessments_address_id_backup table"
    end
  end
end
