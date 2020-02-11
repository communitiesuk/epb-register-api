class AddNotNullConstraintToDomesticEnergy < ActiveRecord::Migration[6.0]
  def change
    change_column_null :domestic_energy_assessments, :date_of_expiry, false
  end
end
