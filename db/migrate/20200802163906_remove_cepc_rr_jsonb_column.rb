class RemoveCepcRrJsonbColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :non_dom_cepc_rr
  end
end
