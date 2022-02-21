class AddAddressBaseVersions < ActiveRecord::Migration[7.0]
  def up
    create_table :address_base_versions, id: false do |t|
      t.string :version_name, null: false
      t.integer :version_number, null: false, index: { unique: true }
      t.datetime :created_at, null: false
    end
  end

  def down
    drop_table :address_base_versions
  end
end
