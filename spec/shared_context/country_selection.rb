shared_context "when selecting a country" do
  def get_country_for_assessment(assessment_id:)
    ActiveRecord::Base.connection.exec_query("SELECT country_name FROM assessments_country_ids a join countries using(country_id) WHERE assessment_id='#{assessment_id}' ").map { |rows| rows["country_name"] }.first
  end
end
