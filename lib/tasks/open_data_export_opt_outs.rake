desc "Exporting hashed assessment_id opt out data for Open Data Communities"

task :open_data_export_opt_out do
  bucket_name = ENV["BUCKET_NAME"]
  instance_name = ENV["INSTANCE_NAME"]

  raise Boundary::ArgumentMissing, "bucket_name or instance_name" unless bucket_name || instance_name

  hashed_assessments = hash_data(export_opted_out_assessments)

  csv_data = Helper::ExportHelper.to_csv(hashed_assessments)
  transmit_opt_out_file(csv_data)

rescue Boundary::RecoverableError => e
  error_output = {
    error: e.class.name,
  }

  error_output[:message] = e.message unless e.message == error_output[:error]
  begin
    error_output[:message] = JSON.parse error_output[:message] if error_output[:message]
  rescue JSON::ParserError
    # ignore
  end

rescue Boundary::TerminableError => e
  warn e.message
end

private

def export_opted_out_assessments
  sql = <<~SQL
    SELECT assessment_id FROM assessments where opt_out = true
  SQL

  results = ActiveRecord::Base.connection.exec_query(sql, "SQL")
  results.map { |result| result }
end

def hash_data(assessments)
  array = []
  assessments.each do |assessment|
    array << { assessment_id: Helper::RrnHelper.hash_rrn(assessment["assessment_id"]) }
  end
  array
end

def transmit_opt_out_file(data)
  filename = "open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv"

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    instance_name: ENV["INSTANCE_NAME"],
    bucket_name: ENV["BUCKET_NAME"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  storage_gateway.write_file(filename, data)
end
