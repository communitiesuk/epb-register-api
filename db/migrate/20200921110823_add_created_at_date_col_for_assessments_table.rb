class AddCreatedAtDateColForAssessmentsTable < ActiveRecord::Migration[6.0]
  def up
    execute("ALTER TABLE assessments ADD created_at timestamp DEFAULT NULL")
    execute("ALTER TABLE assessments ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP")
  end

  def down
    execute("ALTER TABLE assessments DROP created_at")
  end
end
