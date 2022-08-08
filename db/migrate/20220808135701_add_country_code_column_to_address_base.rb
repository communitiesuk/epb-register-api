class AddCountryCodeColumnToAddressBase < ActiveRecord::Migration[7.0]
  def change
    add_column :address_base, :country_code, "char(1)"
  end
end
