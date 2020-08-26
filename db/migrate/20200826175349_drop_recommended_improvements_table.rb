class DropRecommendedImprovementsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :domestic_epc_energy_improvements do |t|
      t.string "assessment_id"
      t.integer "sequence"
      t.string "improvement_code"
      t.string "indicative_cost"
      t.decimal "typical_saving"
      t.string "improvement_category"
      t.string "improvement_type"
      t.integer "energy_performance_rating_improvement"
      t.integer "environmental_impact_rating_improvement"
      t.string "green_deal_category_code"
      t.string "improvement_title"
      t.string "improvement_description"
    end
  end
end
