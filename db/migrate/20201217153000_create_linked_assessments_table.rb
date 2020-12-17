class CreateLinkedAssessmentsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :linked_assessments, primary_key: :assessment_id, id: :string do |t|
      t.string :linked_assessment_id, index: true, null: false
    end
  end
end
