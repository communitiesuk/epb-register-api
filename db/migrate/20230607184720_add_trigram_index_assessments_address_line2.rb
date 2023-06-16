class AddTrigramIndexAssessmentsAddressLine2 < ActiveRecord::Migration[7.0]
  def up
    # remove trigram on assessments tables
    # execute "CREATE INDEX IF NOT EXISTS index_address_line2_on_assessments_trigram ON assessments USING gist (address_line2  gist_trgm_ops)"
  end
end
