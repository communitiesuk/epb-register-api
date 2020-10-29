class CreateAssessmentsAddressIdTable < ActiveRecord::Migration[6.0]
  def change
    create_table :assessments_address_id, primary_key: :assessment_id, id: :string do |t|
      t.string :address_id, index: true
      t.string :source
    end
  end
end
