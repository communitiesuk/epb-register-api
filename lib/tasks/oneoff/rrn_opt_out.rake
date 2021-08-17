# This task requires a list of opted-out RRNs in a CSV format (`.csv`)
require "csv"

namespace :oneoff do
  # This task was used to opt out all RRNs that had previously been opted out on
  # the legacy system.
  desc "Update rrn opt-out data"
  task :update_rrn_opt_out do
    Tasks::TaskHelpers.quit_if_production
    internal_url = ENV["url"]

    puts "Reading opt-out file from: #{internal_url}"

    uri = URI(internal_url)

    opt_out_rrn_csv = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    ) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request.basic_auth ENV["username"], ENV["password"]

      http.request request
    end

    puts "Starting reset opt out query..."

    ActiveRecord::Base.transaction do
      query = "UPDATE assessments SET opt_out = 'f' WHERE opt_out = 't'"
      ActiveRecord::Base.connection.exec_query(query)
    end

    puts "Opt out set to false on all assessments"

    opt_out_rrns = CSV.parse(opt_out_rrn_csv.body).flatten!

    puts "#{opt_out_rrns.count} opt outs have been collected from the csv"

    puts "Starting opt out update query... "

    ActiveRecord::Base.transaction do
      query = "UPDATE assessments SET opt_out = 't' WHERE assessment_id IN(#{opt_out_rrns.map { |rrn| ActiveRecord::Base.connection.quote(rrn) }.join(', ')})"

      ActiveRecord::Base.connection.exec_query(query)
    end

    puts "Opt out query is complete! :-)"
  end
end
