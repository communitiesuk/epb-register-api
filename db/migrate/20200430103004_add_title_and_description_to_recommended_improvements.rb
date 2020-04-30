class AddTitleAndDescriptionToRecommendedImprovements < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_epc_energy_improvements,
               :improvement_title,
               :string
    add_column :domestic_epc_energy_improvements,
               :improvement_description,
               :string
  end
end
