class AlterAssessmentsAddDefaultValues < ActiveRecord::Migration[6.0]
  def up
    change_column :assessments, :property_summary, :jsonb, null: true, default: []
  end

  def down
    change_column :assessments, :property_summary, :jsonb, null: false, default: "[]"
  end
end
