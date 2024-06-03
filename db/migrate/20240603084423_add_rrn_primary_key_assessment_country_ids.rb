class AddRrnPrimaryKeyAssessmentCountryIds < ActiveRecord::Migration[7.1]
  def up
    execute("ALTER TABLE assessments_country_ids ADD PRIMARY KEY (assessment_id);")
  end

  def down
    remove_index :assessments_country_ids, :assessment_id
  end
end
