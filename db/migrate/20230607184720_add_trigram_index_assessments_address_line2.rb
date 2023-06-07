class AddTrigramIndexAssessmentsAddressLine2 < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX IF NOT EXISTS index_address_line2_on_assessments_trigram ON assessments USING gist (address_line2  gist_trgm_ops)"
  end

  def down
    execute "DROP INDEX IF EXISTS index_address_line2_on_assessments_trigram"
  end
end
