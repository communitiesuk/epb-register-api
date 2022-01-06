class AddGdpFuelSavings < ActiveRecord::Migration[6.0]
  def change
    create_table :gdp_fuel_savings, id: false do |t|
      t.string :green_deal_plan_id
      t.integer :sequence
    end

    add_foreign_key :gdp_fuel_savings,
                    :green_deal_plans,
                    column: :green_deal_plan_id,
                    primary_key: :green_deal_plan_id
  end
end
