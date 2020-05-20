class PropertySummary < ActiveRecord::Migration[6.0]
  def change
    add_column :domestic_energy_assessments,
               :property_summary,
               :jsonb,
               null: false,
               default: "{}"
  end
end
