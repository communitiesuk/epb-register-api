class CreateAddressIdBackupTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :lprn_to_rrn, if_exists: true

    create_table :assessments_address_id_backup, primary_key: :assessment_id, id: :string do |t|
      t.string :address_id, index: true
      t.string :source
    end
  end
end
