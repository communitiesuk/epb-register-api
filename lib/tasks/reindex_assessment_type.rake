desc "Reindex assessments table column from XML"

task :reindex_assessment_type do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  assessments = ActiveRecord::Base.connection.execute("
    SELECT
      a.assessment_id, b.xml, b.schema_type
    FROM
      assessments a
    JOIN assessments_xml b
      ON(a.assessment_id = b.assessment_id)
    WHERE
      a.type_of_assessment = '" + ActiveRecord::Base.connection.quote(ENV["type_of_assessment"]) + "'")

  successes = 0
  errors = []

  assessments.each do |assessment|
    report_model = ViewModel::Factory.new.create(assessment["xml"], assessment["schema_type"], assessment["assessment_id"])

    if report_model.nil?
      errors.push(
        {
          assessment_id: assessment["assessment_id"],
          schema_type: assessment["schema_type"],
        }
      )
    else
      report = report_model.to_hash

      ActiveRecord::Base.connection.execute("
        UPDATE
          assessments
        SET
          #{ActiveRecord::Base.connection.quote_column_name(ENV["column"])}
            =
          " + ActiveRecord::Base.connection.quote(report[ENV["value_location"].to_sym]) + "
        WHERE
          assessment_id = " + ActiveRecord::Base.connection.quote(assessment["assessment_id"]) + "
      ")

      successes += 1
    end
  end

  p "Successfully reindexed: #{successes}"
  p "Failed to reindexed: #{errors.count}"
  pp errors
end
