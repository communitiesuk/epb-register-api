class AddTrigramIndexAssessmentSearchAddress < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX IF NOT EXISTS index_address_on_assessment_search_address_trigram ON assessment_search_address USING gin (address  gin_trgm_ops)"
  end

  def down
    execute "DROP INDEX IF EXISTS index_address_on_assessment_search_address_trigram"
  end
end
