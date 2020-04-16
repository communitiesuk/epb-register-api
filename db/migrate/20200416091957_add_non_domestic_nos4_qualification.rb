class AddNonDomesticNos4Qualification < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :non_domestic_nos4_qualification, :string
  end
end
