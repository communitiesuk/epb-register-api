class UpdateAddressLineName < ActiveRecord::Migration[6.0]
  def change
    rename_column :domestic_energy_assessments, :address_line_1, :address_line1
    rename_column :domestic_energy_assessments, :address_line_2, :address_line2
    rename_column :domestic_energy_assessments, :address_line_3, :address_line3
    rename_column :domestic_energy_assessments, :address_line_4, :address_line4
  end
end
