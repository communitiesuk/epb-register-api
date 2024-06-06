class AddIndexCountryIdAssessmentsCountryId < ActiveRecord::Migration[7.1]
  def up
    execute("ALTER TABLE assessments_country_ids ADD CONSTRAINT fks_assessments_country_ids_countries FOREIGN KEY (country_id) REFERENCES countries(country_id) ")
    add_index :assessments_country_ids, :country_id
  end

end
