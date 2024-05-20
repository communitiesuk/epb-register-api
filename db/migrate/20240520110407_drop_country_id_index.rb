class DropCountryIdIndex < ActiveRecord::Migration[7.1]
  def up
    remove_index :assessments, :country_id
  end
end
