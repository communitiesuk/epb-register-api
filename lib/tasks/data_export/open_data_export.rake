namespace :open_data do
  desc "Exporting assessments data for Open Data Communities"
  task :export_assessments, %i[type_of_export assessment_type date_from date_to task_id] do |_, args|
    type_of_export = args.type_of_export
    assessment_type = args.assessment_type&.upcase
    date_from = args.date_from
    date_to =   args.date_to || Time.now.strftime("%F")
    task_id =  args.task_id

    raise Boundary::ArgumentMissing, "type_of_export. You  must specify 'for_odc' or 'not_for_odc'" if type_of_export.nil? || !%w[for_odc not_for_odc].include?(type_of_export)
    raise Boundary::ArgumentMissing, "assessment_type, eg: 'SAP-RDSAP', 'DEC' etc" unless assessment_type
    raise Boundary::ArgumentMissing, "date_from" unless date_from
    raise Boundary::InvalidDates unless date_from <= date_to

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

    raise Boundary::OpenDataEmpty if data.length.zero?

    transmit_file = lambda do |file_data|
      max_task_id = Gateway::OpenDataLogGateway.new.fetch_latest_task_id

      filename =
        if type_of_export == "for_odc"
          "open_data_export_#{assessment_type.downcase}_#{Time.now.strftime('%F')}_#{max_task_id}.csv"
        else
          "test/open_data_export_#{assessment_type.downcase}_#{Time.now.strftime('%F')}_#{max_task_id}.csv"
        end

      storage_config_reader = Gateway::StorageConfigurationReader.new(
        instance_name: ENV["INSTANCE_NAME"],
        bucket_name: ENV["BUCKET_NAME"],
      )
      storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
      storage_gateway.write_file(filename, file_data)
    end

    csv_data = Helper::ExportHelper.to_csv(data)
    transmit_file.call(csv_data)

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
end
