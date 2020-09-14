desc "Update rrn opt-out data"

task :update_rrn_opt_out do
  internal_url = ENV["url"]
  puts "Reading opt-out file from: #{internal_url}"
  uri = URI(internal_url)

  raw_opt_outs = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  ) do |http|
    request = Net::HTTP::Get.new uri.request_uri
    request.basic_auth ENV["username"], ENV["password"]

    http.request request
  end
  parsed_opt_outs = JSON.parse(raw_opt_outs.body)

  reformatted_opt_outs = []
  parsed_opt_outs.each do |node|
    opt_out = node["OPT_OUT"] == "Y" ? "t" : "f"
    reformatted_opt_outs << { date_time: node["REQUEST_TIMESTAMP"], rrn: node["RRN"], opt_out: opt_out }
  end

  ordered_opt_outs = reformatted_opt_outs.sort_by { |node| node[:date_time] }
  ordered_opt_outs.reverse!

  ordered_opt_outs.each do |node|
    first_rrn = node[:rrn]
    first_date = node[:date_time]
    ordered_opt_outs.each do |second_node|
      if first_rrn == second_node[:rrn] && first_date > second_node[:date_time]
        ordered_opt_outs.delete(second_node)
      end
    end
  end

  ActiveRecord::Base.transaction do
    ordered_opt_outs.each do |node|
      query = "UPDATE assessments SET opt_out = '#{node[:opt_out]}' WHERE assessment_id = '#{node[:rrn]}'"

      ActiveRecord::Base.connection.execute(query)
    end
  end
end
