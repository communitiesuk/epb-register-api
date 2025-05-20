class TestMigration < ActiveRecord::Migration[8.0]
  def up
    add_column :assessors, :test_column, :string
  end

  def down
    remove_column :assessors, :test_column
  end
end
