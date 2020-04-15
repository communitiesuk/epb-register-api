class AddNonDomesticNos3Qualification < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :non_domestic_nos3_qualification, :string
  end
end
