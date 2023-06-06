class AddTrigramIndexAssessmentsTowns < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX IF NOT EXISTS index_towns_on_assessments_trigram ON assessments USING gist (town  gist_trgm_ops)"
  end

  def down
    execute "DROP INDEX IF EXISTS index_towns_on_assessments_trigram"
  end
end
