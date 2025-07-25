namespace :data_export do
  desc "Exporting assessments data for Northern Ireland"

  task :ni_assessments, %i[type_of_assessments date_from date_to] do |_, args|
    # use 'SAP-RdSAP' as the type_of_assessments for domestic assessments
    type_of_assessments = args.type_of_assessments || ENV["type_of_assessments"]
    date_from = args.date_from || ENV["date_from"]
    date_to =   args.date_to || ENV["date_to"]

    last_months_dates = Tasks::TaskHelpers.get_last_months_dates
    date_from ||= last_months_dates[:start_date]
    date_to ||= last_months_dates[:end_date]

    raise Boundary::ArgumentMissing, "type_of_assessments" unless type_of_assessments

    exporter = ApiFactory.ni_assessments_export_use_case
    data = exporter.execute(type_of_assessment: type_of_assessments.split("-"), date_from:, date_to:)

    raise Boundary::OpenDataEmpty if data.empty?

    csv_data = Helper::ExportHelper.to_csv(data)
    transmit_ni_file(csv_data, type_of_assessments)
  end
end

def transmit_ni_file(data, type_of_assessments)
  assessment_types = type_of_assessments.is_a?(Array) ? type_of_assessments.join("_") : type_of_assessments
  filename = "ni_assessments_export_#{assessment_types.downcase}_#{Time.now.utc.strftime('%F')}.csv"

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    bucket_name: ENV["BUCKET_NAME"] || ENV["ODE_BUCKET_NAME"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  storage_gateway.write_file(filename, data)
end
