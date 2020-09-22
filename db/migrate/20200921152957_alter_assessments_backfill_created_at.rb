class AlterAssessmentsBackfillCreatedAt < ActiveRecord::Migration[6.0]
  def up
    execute("UPDATE assessments SET created_at = '2020-09-20 15:21:18.341113' WHERE migrated IS NULL")
  end

  def down
    execute("UPDATE assessments SET created_at = NULL WHERE migrated IS NULL")
  end
end
