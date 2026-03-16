class RenameColumnsInAssessorTableForScottishQualifications < ActiveRecord::Migration[8.1]
  def change
    remove_column :assessors, :scotland_rdsap, :string
    remove_column :assessors, :scotland_sap_existing_building, :string
    remove_column :assessors, :scotland_sap_new_building, :string
    remove_column :assessors, :scotland_nondomestic_existing_building, :string
    remove_column :assessors, :scotland_nondomestic_new_building, :string
    remove_column :assessors, :scotland_dec_and_ar, :string
    remove_column :assessors, :scotland_section_63, :string
    add_column :assessors, :scotland_rdsap_qualification, :string, null: true
    add_column :assessors, :scotland_sap_existing_building_qualification, :string, null: true
    add_column :assessors, :scotland_sap_new_building_qualification, :string, null: true
    add_column :assessors, :scotland_nondomestic_existing_building_qualification, :string, null: true
    add_column :assessors, :scotland_nondomestic_new_building_qualification, :string, null: true
    add_column :assessors, :scotland_dec_and_ar_qualification, :string, null: true
    add_column :assessors, :scotland_section63_qualification, :string, null: true
  end

  def down
    remove_column :assessors, :scotland_rdsap_qualification, :string
    remove_column :assessors, :scotland_sap_existing_building_qualification
    remove_column :assessors, :scotland_sap_new_building_qualification, :string
    remove_column :assessors, :scotland_nondomestic_existing_building_qualification, :string
    remove_column :assessors, :scotland_nondomestic_new_building_qualification, :string
    remove_column :assessors, :scotland_dec_and_ar_qualification, :string
    remove_column :assessors, :scotland_section63_qualification, :string
    add_column :assessors, :scotland_rdsap, :string, null: true
    add_column :assessors, :scotland_sap_existing_building, :string, null: true
    add_column :assessors, :scotland_sap_new_building, :string, null: true
    add_column :assessors, :scotland_nondomestic_existing_building, :string, null: true
    add_column :assessors, :scotland_nondomestic_new_building, :string, null: true
    add_column :assessors, :scotland_dec_and_ar, :string, null: true
    add_column :assessors, :scotland_section_63, :string, null: true
  end
end
