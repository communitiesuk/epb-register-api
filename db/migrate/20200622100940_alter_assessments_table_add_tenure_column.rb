class AlterAssessmentsTableAddTenureColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :tenure, :string
  end
end
