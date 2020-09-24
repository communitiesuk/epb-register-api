class ModifyIndexesForAssessmentsForAddressSearch < ActiveRecord::Migration[6.0]
  def up
    remove_index :assessments, :address_line1
    remove_index :assessments, :address_line2
    remove_index :assessments, :town
    execute "CREATE INDEX index_assessments_on_address_line1 ON assessments USING btree (LOWER(address_line1));"
    execute "CREATE INDEX index_assessments_on_address_line2 ON assessments USING btree (LOWER(address_line2));"
    execute "CREATE INDEX index_assessments_on_address_line3 ON assessments USING btree (LOWER(address_line3));"
    execute "CREATE INDEX index_assessments_on_address_line4 ON assessments USING btree (LOWER(address_line4));"
    execute "CREATE INDEX index_assessments_on_town ON assessments USING btree (LOWER(town));"
  end

  def down
    execute "DROP INDEX index_assessments_on_address_line1;"
    execute "DROP INDEX index_assessments_on_address_line2;"
    execute "DROP INDEX index_assessments_on_address_line3;"
    execute "DROP INDEX index_assessments_on_address_line4;"
    execute "DROP INDEX index_assessments_on_town;"
    add_index :assessments, :address_line1
    add_index :assessments, :address_line2
    add_index :assessments, :town
  end
end
