class AddNonDomesticDecAirconQualification < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :non_domestic_dec_qualification, :string
  end
end
