module Boundary
  class BaseError < StandardError; end
  class RecoverableError < BaseError; end
end

desc "Exporting assessments data for Open Data"

private

def set_date_time
  DateTime.now.strftime("%Y%m%dT%H%M")
end

def execute_use_case
  date_time = set_date_time
  if assessment_type == "SAP-RDSAP-RR"
    flattened_data = Helper::ExportHelper.flatten_domestic_rr_response(export_open_data_use_case.execute(date_from))
    data = Helper::ExportHelper.to_csv(flattened_data)
  else
    data = Helper::ExportHelper.to_csv(export_open_data_use_case.execute(date_from))
  end
  data
end

def get_use_case_by_assessment_type(assessment_type)
  export_open_data_use_case = nil
  case assessment_type
  when "CEPC"
    export_open_data_use_case = UseCase::ExportOpenDataCommercial.new
  when "CEPC-RR"
    export_open_data_use_case = UseCase::ExportOpenDataCepcrr.new
  when "DEC"
    export_open_data_use_case = UseCase::ExportOpenDataDec.new
  when "DEC-RR"
    export_open_data_use_case = UseCase::ExportOpenDataDecrr.new
  when "SAP-RDSAP"
    export_open_data_use_case = UseCase::ExportOpenDataDomestic.new
  end
  export_open_data_use_case
end

task :open_data_export do
  bucket = ENV["bucket_name"]
  instance_name = ENV["instance_name"]
  assessment_type = ENV["assessment_type"]
  date_from = ENV["date_from"]

  raise Boundary::ArgumentMissing, "BUCKET" unless bucket
  raise Boundary::ArgumentMissing, "INSTANCE_NAME" unless instance_name
  raise Boundary::ArgumentMissing, "ASSESSMENT_TYPE" unless assessment_type
  raise Boundary::ArgumentMissing, "DATE_FROM" unless date_from

  assessment_type = ENV["assessment_type"].upcase
  export_open_data_use_case = get_use_case_by_assessment_type(assessment_type)
  raise Boundary::InvalidAssessment, ENV["assessment_type"] unless export_open_data_use_case

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    instance_name: ENV["instance_name"],
    bucket_name: ENV["bucket_name"],
  )

  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  data = execute_use_case
  storage_gateway.write_file("open_data_export_#{ENV['assessment_type'].downcase}_#{set_date_time}.csv", data)

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

rescue Boundary::TerminableError, Gateway::StorageConfigurationReader::IllegalCalLException => e
  warn e.message
end

puts "true"
