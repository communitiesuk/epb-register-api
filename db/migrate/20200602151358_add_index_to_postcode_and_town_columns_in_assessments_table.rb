class AddIndexToPostcodeAndTownColumnsInAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    add_index :assessments, :postcode
    add_index :assessments, :town
  end
end
