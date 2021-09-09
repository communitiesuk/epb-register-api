namespace :data_export do
  desc "Exporting assessments data for Northern Ireland"

  task :ni_assessments, %i[type_of_assessments date_from date_to] do |_, args|
    type_of_assessments = args.type_of_assessments
    date_from = args.date_from || "1990-01-01"
    date_to =   args.date_to || Time.now.strftime("%F")

    raise Boundary::ArgumentMissing, "type_of_assessments" unless type_of_assessments


    exporter = ApiFactory.ni_assessments_export_use_case
    data = exporter.execute(type_of_assessment: type_of_assessments.split('-'), date_from: "1990-01-01", date_to: Time.now )

    raise Boundary::OpenDataEmpty if data.length.zero?

    csv_data = Helper::ExportHelper.to_csv(data)
    transmit_ni_file(csv_data, type_of_assessments)
  end
end

private

def transmit_ni_file(data, type_of_assessments)
  assessment_types = type_of_assessments.is_a?(Array) ? type_of_assessments.join("_") : type_of_assessments
  filename = "ni_assessments_export_#{assessment_types.downcase}_#{DateTime.now.strftime('%F')}.csv"

  storage_config_reader = Gateway::StorageConfigurationReader.new(
    instance_name: ENV["INSTANCE_NAME"],
    bucket_name: ENV["BUCKET_NAME"],
  )
  storage_gateway = Gateway::StorageGateway.new(storage_config: storage_config_reader.get_configuration)
  storage_gateway.write_file(filename, data)
end
