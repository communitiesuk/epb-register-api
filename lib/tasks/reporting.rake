desc "Create report in CSV that POSTs data in batches to a URL"

task :extract_reporting do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  puts "Starting extraction at #{Time.now}"

  where = "a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL"

  if ENV["type_of_assessment"]
    where << " AND a.type_of_assessment = #{ActiveRecord::Base.connection.quote(ENV['type_of_assessment'])}"
  end

  if ENV["schema_type"]
    where << " AND b.schema_type = #{ActiveRecord::Base.connection.quote(ENV['schema_type'])}"
  end

  if ENV["from_date"] && ENV["to_date"]
    where << " AND a.date_registered BETWEEN #{ActiveRecord::Base.connection.quote(ENV['from_date'])} AND #{ActiveRecord::Base.connection.quote(ENV['to_date'])}"
  end

  number_of_assessments = ActiveRecord::Base.connection.exec_query("SELECT COUNT(assessment_id) AS number_of_assessments FROM assessments a WHERE #{where}").first["number_of_assessments"]

  puts "Done getting number of assessments. #{number_of_assessments} in total at #{Time.now}"

  start = 0

  while start <= number_of_assessments
    assessments = ActiveRecord::Base.connection.exec_query("
      SELECT
        a.assessment_id, b.xml, b.schema_type, c.address_id
      FROM
        assessments a
      LEFT JOIN
        assessments_xml b
      ON(a.assessment_id = b.assessment_id)
      LEFT JOIN
        assessments_address_id c
      ON(a.assessment_id = c.assessment_id)
      WHERE
        #{where}
      ORDER BY
        a.date_registered
      LIMIT
        " + ENV["batch"] + "
      OFFSET
        " + start.to_s + "
    ")

    puts "Done getting batch #{start} from DB at #{Time.now}"

    data = []

    assessments.each do |assessment|
      report_model = ViewModel::Factory.new.create(assessment["xml"], assessment["schema_type"], assessment["assessment_id"])

      hash = report_model.to_hash

      data.push(
        {
          type_of_assessment: hash[:type_of_assessment],
          assessment_id: hash[:assessment_id],
          date_of_expiry: hash[:date_of_expiry],
          report_type: hash[:report_type],
          date_of_assessment: hash[:date_of_assessment],
          date_of_registration: hash[:date_of_registration],
          address_id: assessment["address_id"],
          address_line1: hash[:address][:address_line1],
          address_line2: hash[:address][:address_line2],
          address_line3: hash[:address][:address_line3],
          address_line4: hash[:address][:address_line4],
          town: hash[:address][:town],
          postcode: hash[:address][:postcode],
          scheme_assessor_id: hash[:assessor][:scheme_assessor_id],
        },
      )
    end

    puts "Done preparing array for CSV at #{Time.now}"

    internal_url = ENV["url"]

    uri = URI(internal_url)

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    ) do |http|
      request = Net::HTTP::Post.new uri.request_uri
      request.basic_auth ENV["username"], ENV["password"]
      request.body = CSV.generate(
        write_headers: start.zero?, headers: data.first ? data.first.keys : [],
      ) { |csv| data.each { |row| csv << row } }

      http.request request
    end

    puts "Done sending the request at #{Time.now}"

    if response.body != "DONE"
      puts "Failed batch #{start} with error #{response.body}"
    end

    start += ENV["batch"].to_i

    if ENV["max_runs"] && ENV["max_runs"].to_i <= start
      puts "Exiting as max runs was reached"
      break
    end
  end
end
