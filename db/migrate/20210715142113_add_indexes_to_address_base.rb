class AddIndexesToAddressBase < ActiveRecord::Migration[6.1]
  def change
    add_index :address_base, :address_line1
    add_index :address_base, :address_line2
    add_index :address_base, :town
  end
end
