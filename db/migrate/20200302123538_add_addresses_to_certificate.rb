class AddAddressesToCertificate < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments, :address_line_1, :string
    add_column :domestic_energy_assessments, :address_line_2, :string
    add_column :domestic_energy_assessments, :address_line_3, :string
    add_column :domestic_energy_assessments, :address_line_4, :string
    add_column :domestic_energy_assessments, :town, :string
  end
end
