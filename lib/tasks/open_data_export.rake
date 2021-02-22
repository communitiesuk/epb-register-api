desc "Exporting assessments data for Open Data"

private

def set_date_time
  DateTime.now.strftime("%Y%m%dT%H%M")
end

# def convert_data_to_csv(data, assessment_type)
#   if assessment_type == "SAP-RDSAP-RR"
#     flattened_data = Helper::ExportHelper.flatten_domestic_rr_response(data)
#     data = Helper::ExportHelper.to_csv(flattened_data)
#     data.headers = Helper::ExportHelper.convert_header_values(data.headers)
#   else
#     data = Helper::ExportHelper.to_csv(data)
#   end
#   data
# end

def transmit_file(data)
  storage_config_reader = Gateway::StorageConfigurationReader.new(
    instance_name: ENV["instance_name"],
    bucket_name: ENV["bucket_name"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  storage_gateway.write_file("open_data_export_#{ENV['assessment_type'].downcase}_#{set_date_time}.csv", data)
end

def output_completed_task
  gateway = Gateway::OpenDataLogGateway.new
  pp gateway.fetch_log_statistics
end

def get_use_case_by_assessment_type(assessment_type)
  open_data_use_case = nil
  case assessment_type
  when "CEPC"
    open_data_use_case = UseCase::ExportOpenDataCommercial.new
  when "CEPC-RR"
    open_data_use_case = UseCase::ExportOpenDataCepcrr.new
  when "DEC"
    open_data_use_case = UseCase::ExportOpenDataDec.new
  when "DEC-RR"
    open_data_use_case = UseCase::ExportOpenDataDecrr.new
  when "SAP-RDSAP"
    open_data_use_case = UseCase::ExportOpenDataDomestic.new
  end
  open_data_use_case
end

task :open_data_export do
  bucket = ENV["bucket_name"]
  instance_name = ENV["instance_name"]
  assessment_type = ENV["assessment_type"]
  date_from = ENV["date_from"]
  task_id = 0
  unless ENV["task_id"]
    task_id = ENV["task_id"].to_i
  end

  raise Boundary::ArgumentMissing, "BUCKET" unless bucket
  raise Boundary::ArgumentMissing, "INSTANCE_NAME" unless instance_name
  raise Boundary::ArgumentMissing, "ASSESSMENT_TYPE" unless assessment_type
  raise Boundary::ArgumentMissing, "DATE_FROM" unless date_from

  assessment_type = assessment_type.upcase
  open_data_use_case = get_use_case_by_assessment_type(assessment_type)
  raise Boundary::InvalidAssessment, ENV["assessment_type"] unless open_data_use_case

  data = open_data_use_case.execute(date_from, task_id)

  if data.length > 0
    csv_data = Helper::ExportHelper.convert_data_to_csv(data, assessment_type)
    transmit_file(csv_data)
    output_completed_task
    puts "true"
  else
    puts "no data to export"
  end
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
