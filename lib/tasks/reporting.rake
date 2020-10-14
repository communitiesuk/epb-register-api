desc "Create report in CSV that POSTs data in batches to a URL"

task :extract_reporting do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  puts "Starting extraction at #{Time.now}"

  number_of_assessments = ActiveRecord::Base.connection.execute("SELECT COUNT(assessment_id) AS number_of_assessments FROM assessments").first["number_of_assessments"]

  puts "Done getting number of assessments. #{number_of_assessments} in total at #{Time.now}"

  start = 0

  while start <= number_of_assessments
    assessments = ActiveRecord::Base.connection.execute("
      SELECT
        assessment_id, xml, schema_type
      FROM
        assessments_xml
      ORDER BY
        assessment_id
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
          address_id: hash[:address][:address_id],
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
        write_headers: (start == 0), headers: data.first ? data.first.keys : [],
      ) { |csv| data.each { |row| csv << row } }

      http.request request
    end

    puts "Done sending the request at #{Time.now}"

    if response.body != "DONE"
      puts "Failed batch " + start.to_s + " with error " + response.body
    end

    start += ENV["batch"].to_i
  end
end
