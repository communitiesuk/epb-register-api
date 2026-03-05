class AddColumnsToAssessorTableForScottishQualifications < ActiveRecord::Migration[8.1]
  def change
    add_column :assessors, :scotland_rdsap, :string, null: true
    add_column :assessors, :scotland_sap_existing_building, :string, null: true
    add_column :assessors, :scotland_sap_new_building, :string, null: true
    add_column :assessors, :scotland_nondomestic_existing_building, :string, null: true
    add_column :assessors, :scotland_nondomestic_new_building, :string, null: true
    add_column :assessors, :scotland_dec_and_ar, :string, null: true
    add_column :assessors, :scotland_section_63, :string, null: true
  end

  def down
    remove_column :assessors, :scotland_rdsap, :string
    remove_column :assessors, :scotland_sap_existing_building, :string
    remove_column :assessors, :scotland_sap_new_building, :string
    remove_column :assessors, :scotland_nondomestic_existing_building, :string
    remove_column :assessors, :scotland_nondomestic_new_building, :string
    remove_column :assessors, :scotland_dec_and_ar, :string
    remove_column :assessors, :scotland_section_63, :string
  end
end
