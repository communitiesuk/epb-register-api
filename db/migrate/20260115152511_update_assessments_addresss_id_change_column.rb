class UpdateAssessmentsAddresssIdChangeColumn < ActiveRecord::Migration[8.1]
  def change
    remove_column :assessments_address_id, :matched_address_id, :string
    add_column :assessments_address_id, :matched_uprn, :string, limit: 20
    remove_column "scotland.assessments_address_id", :matched_address_id, :string
    add_column "scotland.assessments_address_id", :matched_uprn, :string, limit: 20
  end
end
