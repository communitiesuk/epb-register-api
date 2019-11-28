class AddUniqueIndexToSchemeName < ActiveRecord::Migration[6.0]
  def change
    add_index :schemes, :name, unique: true
  end
end
