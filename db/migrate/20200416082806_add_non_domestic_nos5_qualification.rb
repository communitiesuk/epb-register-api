class AddNonDomesticNos5Qualification < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :non_domestic_nos5_qualification, :string
  end
end
