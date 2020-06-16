class AddMigrateBooleanToAssessments < ActiveRecord::Migration[6.0]
  def change
    def change
      add_column :assessments,
                 :migrated,
                 :boolean,
                 default: false
    end
  end
end
