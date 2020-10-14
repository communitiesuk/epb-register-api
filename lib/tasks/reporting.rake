desc "Create report in CSV that POSTs data in batches to a URL"

task :extract_reporting do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  number_of_assessments = ActiveRecord::Base.connection.execute("SELECT COUNT(assessment_id) AS number_of_assessments FROM assessments").first["number_of_assessments"]

  start = 0

  while start <= number_of_assessments
    assessments = ActiveRecord::Base.connection.execute("
      SELECT
        assessment_id, xml, schema_type
      FROM
        assessments_xml
      LIMIT
        " + ENV["batch"] + "
      OFFSET
        " + start.to_s + "
    ")

    data = []

    assessments.each do |assessment|
      report_model = ViewModel::Factory.new.create(assessment["xml"], assessment["schema_type"], assessment["assessment_id"])

      data.push(
        {
          type_of_assessment: report_model[:type_of_assessment],
          assessment_id: report_model[:assessment_id],
          date_of_expiry: report_model[:date_of_expiry],
          report_type: report_model[:report_type],
          date_of_assessment: report_model[:date_of_assessment],
          date_of_registration: report_model[:date_of_registration],
          address_id: report_model[:address_id],
          address_line1: report_model[:address_line1],
          address_line2: report_model[:address_line2],
          address_line3: report_model[:address_line3],
          address_line4: report_model[:address_line4],
          town: report_model[:town],
          postcode: report_model[:postcode],
          scheme_assessor_id: report_model[:scheme_assessor_id],
        },
      )
    end

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

    if response.body != "DONE"
      puts "FAILED ON BATCH " + start.to_s + " with " + response.body
    end

    start += ENV["batch"].to_i
  end
end
