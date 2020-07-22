class NonDomCepcRr < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :non_dom_cepc_rr, :jsonb, null: false, default: "{}"
  end
end
