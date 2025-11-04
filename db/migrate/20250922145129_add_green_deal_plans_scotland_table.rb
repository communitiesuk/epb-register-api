class AddGreenDealPlansScotlandTable < ActiveRecord::Migration[8.0]
  def change
    create_table "scotland.green_deal_plans", primary_key: :green_deal_plan_id, id: false do |t|
      t.string :green_deal_plan_id
      t.datetime :start_date
      t.datetime :end_date
      t.string :provider_name
      t.string :provider_telephone
      t.string :provider_email
      t.decimal :interest_rate
      t.boolean :fixed_interest_rate
      t.decimal :charge_uplift_amount
      t.datetime :charge_uplift_date
      t.boolean :cca_regulated
      t.boolean :structure_changed
      t.boolean :measures_removed
      t.jsonb :measures, null: false, default: "[]"
      t.jsonb :charges, null: false, default: "[]"
      t.jsonb :savings, null: false, default: "[]"
      t.index "scotland.green_deal_plans", :green_deal_plan_id, unique: true
    end

    add_foreign_key "scotland.green_deal_assessments",
                    "scotland.green_deal_plans",
                    column: :green_deal_plan_id, primary_key: :green_deal_plan_id
  end
end
