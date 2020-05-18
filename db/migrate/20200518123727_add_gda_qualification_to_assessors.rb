class AddGdaQualificationToAssessors < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :gda_qualification, :string
  end
end
