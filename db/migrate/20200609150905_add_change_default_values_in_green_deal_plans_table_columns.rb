class AddChangeDefaultValuesInGreenDealPlansTableColumns < ActiveRecord::Migration[
  6.0
]
  def change
    change_column_default :green_deal_plans, :measures, "[]"

    change_column_default :green_deal_plans, :charges, "[]"

    change_column_default :green_deal_plans, :savings, "[]"
  end
end
