class TestTwo < ActiveRecord::Migration[8.0]
  def up
    add_column :assessments, :test_column_scotland, :string
  end

  def down
    remove_column :assessments, :test_column_scotland
  end
end
