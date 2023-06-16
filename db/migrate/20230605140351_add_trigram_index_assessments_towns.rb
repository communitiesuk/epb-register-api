class AddTrigramIndexAssessmentsTowns < ActiveRecord::Migration[7.0]
  def up
    # remove trigram on assessments tables
    # execute "CREATE INDEX IF NOT EXISTS index_towns_on_assessments_trigram ON assessments USING gist (town  gist_trgm_ops)"
  end
end
