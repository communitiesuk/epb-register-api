class AddDomesticEpcImprovements < ActiveRecord::Migration[6.0]
  def change
    create_table :domestic_epc_energy_improvements, id: false do |t|
      t.string :assessment_id
      t.integer :sequence
    end

    add_foreign_key :domestic_epc_energy_improvements,
                    :domestic_energy_assessments,
                    column: :assessment_id, primary_key: :assessment_id
  end
end
