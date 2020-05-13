class ChangeDefaultPropertySummaryValue < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:assessments, :property_summary, from: "{)", to: "[]")
  end
end
