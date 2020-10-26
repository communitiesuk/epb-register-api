desc "Reindex assessments table column from XML"

task :reindex_assessment_type do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  sql = "
    SELECT
      a.assessment_id, b.xml, b.schema_type, a." + ENV["column"] + " AS column_value
    FROM
      assessments a
    JOIN assessments_xml b
      ON(a.assessment_id = b.assessment_id)
    WHERE "

  if ENV["type_of_assessment"]
    sql << "a.type_of_assessment = " + ActiveRecord::Base.connection.quote(ENV["type_of_assessment"])
  elsif ENV["schema_type"]
    sql << "b.schema_type = " + ActiveRecord::Base.connection.quote(ENV["schema_type"])
  end

  assessments = ActiveRecord::Base.connection.execute(sql)

  successes = 0
  skipped = 0
  errors = []

  assessments.each do |assessment|
    report_model = ViewModel::Factory.new.create(assessment["xml"], assessment["schema_type"], assessment["assessment_id"])

    if report_model.nil?
      errors.push(
        {
          assessment_id: assessment["assessment_id"],
          schema_type: assessment["schema_type"],
        },
      )
    else
      report = report_model.to_hash

      value = report[ENV["value_location"].to_sym]

      if value == assessment["column_value"]
        skipped += 1
      elsif !value.nil?
        ActiveRecord::Base.connection.execute("
          UPDATE
            assessments
          SET
            #{ActiveRecord::Base.connection.quote_column_name(ENV['column'])}
              =
            " + ActiveRecord::Base.connection.quote(value) + "
          WHERE
            assessment_id = " + ActiveRecord::Base.connection.quote(assessment["assessment_id"]) + "
        ")

        successes += 1
      else
        errors.push(
          {
            assessment_id: assessment["assessment_id"],
            schema_type: assessment["schema_type"],
            value: value,
          },
        )
      end
    end
  end

  p "Successfully reindexed: #{successes}"
  p "Skipped: #{skipped}"
  p "Failed to reindexed: #{errors.count}"
  pp errors
end
