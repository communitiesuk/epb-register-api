class AddAddressTypeAndClassToAddressBase < ActiveRecord::Migration[6.1]
  def change
    add_column :address_base, :classification_code, :string, :limit => 6
    add_column :address_base, :address_type, :string, :limit => 15
  end
end
