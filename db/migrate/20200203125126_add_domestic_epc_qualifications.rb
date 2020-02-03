class AddDomesticEpcQualifications < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :domestic_energy_performance_qualification, :string
  end
end
