desc "Update assessments table column from XML"

task :update_assessment_column do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  puts "Starting column update for #{ENV['column']} at #{Time.now}"

  where = if ENV["type_of_assessment"]
            "a.type_of_assessment = #{ActiveRecord::Base.connection.quote(ENV['type_of_assessment'])}"
          elsif ENV["schema_type"]
            "b.schema_type = #{ActiveRecord::Base.connection.quote(ENV['schema_type'])}"
          end

  number_of_assessments = ActiveRecord::Base.connection.exec_query("SELECT
      COUNT(a.assessment_id) AS number_of_assessments
    FROM
      assessments a
    JOIN assessments_xml b
      ON(a.assessment_id = b.assessment_id)
    WHERE " + where).first["number_of_assessments"]

  puts "Done getting number of assessments. #{number_of_assessments} in total at #{Time.now}"

  start = 0

  while start <= number_of_assessments
    sql = "
      SELECT
        a.assessment_id, b.xml, b.schema_type, a." + ENV["column"] + " AS column_value
      FROM
        assessments a
      JOIN assessments_xml b
        ON(a.assessment_id = b.assessment_id)
      WHERE " + where + "
      ORDER BY a.assessment_id
      LIMIT " + ENV["batch"] + "
      OFFSET " + start.to_s

    assessments = ActiveRecord::Base.connection.exec_query(sql)

    puts "Done getting batch #{start} from DB at #{Time.now}"

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
          ActiveRecord::Base.connection.exec_query("
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

    puts "Done updating assessments in DB at #{Time.now}"

    start += ENV["batch"].to_i
  end

  p "Successfully reindexed: #{successes}"
  p "Skipped: #{skipped}"
  p "Failed to reindexed: #{errors.count}"
  pp errors
end
