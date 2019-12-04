class CreateAssessors < ActiveRecord::Migration[6.0]
  def change
    create_table :assessors, { id: false } do |t|
      t.string :first_name
      t.string :last_name
      t.string :middle_names
      t.datetime :date_of_birth
      t.bigint :registered_by, index: true
      t.string :scheme_assessor_id
    end

    add_foreign_key :assessors,
                    :schemes,
                    column: :registered_by, primary_key: :scheme_id
    execute('ALTER TABLE assessors ADD PRIMARY KEY (scheme_assessor_id)')
  end
end
