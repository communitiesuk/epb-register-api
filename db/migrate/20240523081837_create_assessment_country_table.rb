class CreateAssessmentCountryTable < ActiveRecord::Migration[7.1]
  def up
    create_table :assessments_country_ids, id: false do |t|
      t.string :assessment_id
      t.integer :country_id
    end
  end

  def down
    drop_table :assessments_country_ids
  end
end
