class AddNonDomesticCc4AirconQualification < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :non_domestic_cc4_qualification, :string
  end
end
