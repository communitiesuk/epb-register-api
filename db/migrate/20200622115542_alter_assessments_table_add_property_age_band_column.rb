class AlterAssessmentsTableAddPropertyAgeBandColumn < ActiveRecord::Migration[
  6.0
]
  def change
    add_column :assessments, :property_age_band, :string
  end
end
