class CreateAddressBase < ActiveRecord::Migration[6.0]
  def change
    create_table :address_base, { id: false } do |t|
      t.string :uprn
      t.string :postcode, index: true
      t.string :address_line1
      t.string :address_line2
      t.string :address_line3
      t.string :address_line4
      t.string :town
    end

    execute("ALTER TABLE address_base ADD PRIMARY KEY (uprn)")
  end
end
