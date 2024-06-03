class DropCountryIdFromAssessments < ActiveRecord::Migration[7.1]
  def up
    remove_column :assessments, :country_id
  end
end
