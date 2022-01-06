class CreateGreenDealPlansTable < ActiveRecord::Migration[6.0]
  def change
    create_table :green_deal_plans, id: false do |t|
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
    end

    execute("ALTER TABLE green_deal_plans ADD PRIMARY KEY (green_deal_plan_id)")
  end
end
