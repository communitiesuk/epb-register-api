class AddCountryIdToAssessments < ActiveRecord::Migration[7.1]
  def change
    add_column :assessments, :country_id, :bigint, null: true
    add_index :assessments, :country_id
  end

  def down
    remove_column :assessments, :country_id, :bigint
  end
end
