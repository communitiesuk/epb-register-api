class RemovePropertySummaryFromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :property_summary, :jsonb
  end
end
