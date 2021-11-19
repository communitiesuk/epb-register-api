class AddCountryAssessmentStatistics < ActiveRecord::Migration[6.1]
  def change
    add_column :assessment_statistics, :country, :string
  end
end
