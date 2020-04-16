class AddDomesticSapQualification < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :domestic_sap_qualification, :string
  end
end
