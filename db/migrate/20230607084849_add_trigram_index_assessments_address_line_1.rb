class AddTrigramIndexAssessmentsAddressLine1 < ActiveRecord::Migration[7.0]
  def up
    # removed as these specific trigram indexes didn't work and were dropped soon after
    # execute "CREATE INDEX IF NOT EXISTS index_towns_on_assessments_trigram ON assessments USING gist (town  gist_trgm_ops)"
  end
end
