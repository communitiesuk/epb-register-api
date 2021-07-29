desc "Exporting assessments data for Open Data Communities"

task :open_data_export, %i[type_of_export assessment_type date_from date_to] do |_, args|
  bucket = ENV["BUCKET_NAME"]
  instance_name = ENV["INSTANCE_NAME"]

  type_of_export = args.type_of_export
  assessment_type = args.assessment_type&.upcase
  date_from = args.date_from
  date_to =   args.date_to || DateTime.now.strftime("%F")
  task_id =  args.task_id

  raise Boundary::ArgumentMissing, "type_of_export. You  must specify 'for_odc' or 'not_for_odc'" if type_of_export.nil? || !%w[for_odc not_for_odc].include?(type_of_export)
  raise Boundary::ArgumentMissing, "assessment_type, eg: 'SAP-RDSAP', 'DEC' etc" unless assessment_type
  raise Boundary::ArgumentMissing, "date_from" unless date_from
  raise Boundary::InvalidDates unless validate_date_range(date_from, date_to)

  open_data_use_case = get_use_case_by_assessment_type(assessment_type)
  raise Boundary::InvalidAssessment, assessment_type unless open_data_use_case

  data = open_data_use_case.execute(date_from, task_id, date_to)

  raise Boundary::OpenDataEmpty if data.length.zero?

  csv_data = Helper::ExportHelper.to_csv(data)
  transmit_file(csv_data, type_of_export, assessment_type)

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

def set_date_time
  DateTime.now.strftime("%Y%m%dT%H%M")
end

def transmit_file(data, type_of_export, assessment_type)
  filename =
    if type_of_export == "for_odc"
      "open_data_export_#{assessment_type.downcase}_#{DateTime.now.strftime('%F')}_#{get_max_task_id}.csv"
    else
      "test/open_data_export_#{assessment_type.downcase}_#{DateTime.now.strftime('%F')}_#{get_max_task_id}.csv"
    end

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    instance_name: ENV["INSTANCE_NAME"],
    bucket_name: ENV["BUCKET_NAME"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  storage_gateway.write_file(filename, data)
end

def get_max_task_id
  gateway = Gateway::OpenDataLogGateway.new
  gateway.fetch_latest_task_id
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
  when "SAP-RDSAP-RR"
    open_data_use_case = UseCase::ExportOpenDataDomesticrr.new
  end
  open_data_use_case
end
