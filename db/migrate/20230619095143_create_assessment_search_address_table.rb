class CreateAssessmentSearchAddressTable < ActiveRecord::Migration[7.0]
  def up
    create_table :assessment_search_address, id: false do |t|
      t.string :assessment_id, primary_key: true
      t.text :address
    end
  end

  def down
    drop_table :assessment_search_address, if_exists: true
  end
end
