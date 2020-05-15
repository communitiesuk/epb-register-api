class AddAdditionalInformationToAssessorsTable < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :related_party_disclosure_number, :string
    add_column :assessors, :also_known_as, :string
    add_column :assessors, :address_line1, :string
    add_column :assessors, :address_line2, :string
    add_column :assessors, :address_line3, :string
    add_column :assessors, :town, :string
    add_column :assessors, :postcode, :string
    add_column :assessors, :company_reg_no, :string
    add_column :assessors, :company_address_line1, :string
    add_column :assessors, :company_address_line2, :string
    add_column :assessors, :company_address_line3, :string
    add_column :assessors, :company_town, :string
    add_column :assessors, :company_postcode, :string
    add_column :assessors, :company_website, :string
    add_column :assessors, :company_telephone_number, :string
    add_column :assessors, :company_email, :string
    add_column :assessors, :company_name, :string
  end
end
