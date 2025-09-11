class TestScotlandMigrations < ActiveRecord::Migration[8.0]
  def up
    create_table "scotland.scotland_test_table", primary_key: :scheme_id do |t|
      t.string :nessy_present
    end
  end

  def down
    drop_table :scotland_test_table
  end
end
