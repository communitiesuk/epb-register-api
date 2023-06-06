class AddTrigramIndexAssessmentsTowns < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX index_towns_on_assessments_trigram ON assessments USING gist (town  gist_trgm_ops)"
  end

  def down
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
