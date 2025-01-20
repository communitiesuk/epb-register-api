namespace :maintenance do
  desc "Update the country_id for assessments already with an country id"
  task :update_country_ids do
    assessments_ids = ENV["ASSESSMENTS_IDS"]
    raise Boundary::ArgumentMissing, "assessments_ids. You  must specify an ASSESSMENTS_IDS" unless assessments_ids

    use_case = ApiFactory.update_country_id_use_case
    begin
      use_case.execute(assessments_ids:)
    rescue Boundary::TerminableError => e
      puts e.message
    end
  end
end
