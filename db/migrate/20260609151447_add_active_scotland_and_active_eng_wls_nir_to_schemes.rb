class AddActiveScotlandAndActiveEngWlsNirToSchemes < ActiveRecord::Migration[8.1]
  def change
    add_column :schemes, :active_scotland, :boolean, default: false
    add_column :schemes, :active_eng_wls_nir, :boolean, default: false
  end

  def down
    remove_column :schemes, :active_scotland, :boolean
    remove_column :schemes, :active_eng_wls_nir, :boolean
  end
end
