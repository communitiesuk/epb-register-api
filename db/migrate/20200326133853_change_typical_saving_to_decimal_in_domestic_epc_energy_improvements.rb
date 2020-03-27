class ChangeTypicalSavingToDecimalInDomesticEpcEnergyImprovements < ActiveRecord::Migration[6.0]
  def change
     change_column :domestic_epc_energy_improvements, :typical_saving, :decimal
  end
end
