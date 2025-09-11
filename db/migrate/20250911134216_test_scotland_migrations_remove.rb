class TestScotlandMigrationsRemove < ActiveRecord::Migration[8.0]
  def change
    drop_table "scotland.scotland_test_table"
  end
end
