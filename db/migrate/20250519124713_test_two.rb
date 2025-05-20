class TestTwo < ActiveRecord::Migration[8.0]
  def up
    add_column :assessments, :test_column, :string
  end

  def down
    remove_column :assessments, :test_column
  end
end
