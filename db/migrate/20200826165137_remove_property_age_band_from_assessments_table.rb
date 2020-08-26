class RemovePropertyAgeBandFromAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :property_age_band, :string
  end
end
