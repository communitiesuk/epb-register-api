desc "Reindex DEC to get correct date_of_expiry"

task :reindex_dec do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  decs = ActiveRecord::Base.connection.execute("
    SELECT
      a.assessment_id, b.xml, b.schema_type
    FROM
      assessments a
    JOIN assessments_xml b
      ON(a.assessment_id = b.assessment_id)
    WHERE
      a.type_of_assessment = 'DEC'")

  decs.each do |dec|
    report = ViewModel::Factory.new.create(dec["xml"], dec["schema_type"], dec["assessment_id"]).to_hash

    ActiveRecord::Base.connection.execute("
      UPDATE
        assessments
      SET
        date_of_expiry = " + ActiveRecord::Base.connection.quote(report[:date_of_expiry]) + "
      WHERE
        assessment_id = " + ActiveRecord::Base.connection.quote(dec["assessment_id"]) + "
    ")
  end
end
