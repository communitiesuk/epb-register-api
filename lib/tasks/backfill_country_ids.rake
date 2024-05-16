namespace :maintenance do
  desc "Update assessments table with values for country_id"
  task :backfill_country_ids do
    date_from = ENV["DATE_FROM"]
    date_to   = ENV["DATE_TO"]
    assessment_types = ENV["ASSESSMENT_TYPES"]&.split(",")

    raise Boundary::ArgumentMissing, "date_from. You  must specify an DATE_FROM" unless date_from
    raise Boundary::ArgumentMissing, "date_to. You  must specify an DATE_TO" unless date_to

    use_case = ApiFactory.backfill_country_id_use_case
    begin
      use_case.execute(date_from:, date_to:, assessment_types:)
    rescue Boundary::TerminableError => e
      puts e.message
    end
  end
end
