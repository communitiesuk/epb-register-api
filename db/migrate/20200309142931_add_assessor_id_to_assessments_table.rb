class AddAssessorIdToAssessmentsTable < ActiveRecord::Migration[6.0]
  def up
    add_column :domestic_energy_assessments, :scheme_assessor_id, :string
    change_column_null :domestic_energy_assessments,
                       :scheme_assessor_id,
                       false,
                       "TESTASSESSOR"

    add_foreign_key :domestic_energy_assessments,
                    :assessors,
                    column: :scheme_assessor_id,
                    primary_key: :scheme_assessor_id
  end

  def down
    remove_column :domestic_energy_assessments, :scheme_assessor_id, :string
  end
end
