namespace :open_data do
  desc "Exporting assessments data for Open Data Communities"
  task :export_assessments, %i[type_of_export assessment_type date_from date_to task_id] do |_, args|
    type_of_export = args.type_of_export || ENV["type_of_export"]
    assessment_type = args.assessment_type&.upcase || ENV["assessment_type"]&.upcase
    date_from = args.date_from || ENV["date_from"]
    date_to =   args.date_to || ENV["date_to"]
    task_id = args.task_id || ENV["task_id"]

    last_months_dates = Tasks::TaskHelpers.get_last_months_dates
    date_from ||= last_months_dates[:start_date]
    date_to ||= last_months_dates[:end_date]

    raise Boundary::ArgumentMissing, "type_of_export. You  must specify 'for_odc' or 'not_for_odc'" if type_of_export.nil? || !%w[for_odc not_for_odc].include?(type_of_export)
    raise Boundary::ArgumentMissing, "assessment_type, eg: 'SAP-RDSAP', 'DEC' etc" unless assessment_type

    open_data_use_case = case assessment_type
                         when "CEPC"
                           UseCase::ExportOpenDataCommercial.new
                         when "CEPC-RR"
                           UseCase::ExportOpenDataCepcrr.new
                         when "DEC"
                           UseCase::ExportOpenDataDec.new
                         when "DEC-RR"
                           UseCase::ExportOpenDataDecrr.new
                         when "SAP-RDSAP"
                           UseCase::ExportOpenDataDomestic.new
                         when "SAP-RDSAP-RR"
                           UseCase::ExportOpenDataDomesticrr.new
                         else
                           nil
                         end

    raise Boundary::InvalidAssessment, assessment_type unless open_data_use_case

    data = open_data_use_case.execute(date_from, task_id, date_to)

    raise Boundary::OpenDataEmpty if data.empty?

    data = Helper::ExportHelper.remove_line_breaks_from_hash_values(data)

    transmit_file = lambda do |file_data|
      max_task_id = Gateway::OpenDataLogGateway.new.fetch_latest_task_id

      filename =
        if type_of_export == "for_odc"
          "open_data_export_#{assessment_type.downcase}_#{Time.now.strftime('%F')}_#{max_task_id}.csv"
        else
          "test/open_data_export_#{assessment_type.downcase}_#{Time.now.strftime('%F')}_#{max_task_id}.csv"
        end

      storage_config_reader = Gateway::StorageConfigurationReader.new(
        bucket_name: ENV["BUCKET_NAME"] || ENV["ODE_BUCKET_NAME"],
      )
      storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
      storage_gateway.write_file(filename, file_data)
    end

    data = Helper::ExportHelper.to_csv(data)
    transmit_file.call(data)
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
    e.message
    raise
  end

  desc "Exporting assessments data for Open Data Communities by hashed assessment id"
  task :export_assessments_by_hashed_assessment_id, %i[hashed_assessment_ids type_of_export task_id] do |_, args|
    raise Boundary::ArgumentMissing, "hashed_assessment_ids. You must include a list of hashed assessment ids" unless args.hashed_assessment_ids
    raise Boundary::ArgumentMissing, "type_of_export. You must specify 'for_odc' or 'not_for_odc'" if args.type_of_export.nil? || !%w[for_odc not_for_odc].include?(args.type_of_export)

    hashed_assessment_ids = args.hashed_assessment_ids.split(" ")
    type_of_export = args.type_of_export
    task_id = args.task_id

    open_data_use_case = UseCase::ExportOpenDataDomestic.new

    data = open_data_use_case.execute_using_hashed_assessment_id(hashed_assessment_ids, task_id)

    raise Boundary::OpenDataEmpty, "split_hashed_assessments_id: #{hashed_assessment_ids}, hashed_assessment_id_args: #{args.hashed_assessment_ids}data: #{data}" if data.empty?

    data = Helper::ExportHelper.remove_line_breaks_from_hash_values(data)

    transmit_file = lambda do |file_data|
      max_task_id = Gateway::OpenDataLogGateway.new.fetch_latest_task_id

      filename =
        if type_of_export == "for_odc"
          "open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_#{max_task_id}.csv"
        else
          "test/open_data_export_by_hashed_assessment_id_sap-rdsap_#{Time.now.strftime('%F')}_#{max_task_id}.csv"
        end

      storage_config_reader = Gateway::StorageConfigurationReader.new(
        bucket_name: ENV["BUCKET_NAME"] || ENV["ODE_BUCKET_NAME"],
      )
      storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
      storage_gateway.write_file(filename, file_data)
    end

    data = Helper::ExportHelper.to_csv(data)
    transmit_file.call(data)
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
    e.message
    raise
  end
end
