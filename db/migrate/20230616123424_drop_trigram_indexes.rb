class DropTrigramIndexes < ActiveRecord::Migration[7.0]
  def change
    execute "DROP INDEX IF EXISTS index_address_line2_on_assessments_trigram"
    execute "DROP INDEX IF EXISTS index_address_line1_on_assessments_trigram"
    execute "DROP INDEX IF EXISTS index_towns_on_assessments_trigram"
  end
end
