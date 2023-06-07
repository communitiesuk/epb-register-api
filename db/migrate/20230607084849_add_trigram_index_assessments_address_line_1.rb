class AddTrigramIndexAssessmentsAddressLine1 < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX IF NOT EXISTS index_address_line1_on_assessments_trigram ON assessments USING gist (address_line1  gist_trgm_ops)"
  end

  def down
    execute "DROP INDEX IF EXISTS index_address_line1_on_assessments_trigram"
  end
end
