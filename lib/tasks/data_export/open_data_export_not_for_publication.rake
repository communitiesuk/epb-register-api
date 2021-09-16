require_relative "./open_data_export_helper"

namespace :open_data do
  desc "Exporting hashed assessment_id opt out, cancelled or not for issue data for Open Data Communities"
  task :export_not_for_publication, %i[type_of_export] do |_, arg|
    type_of_export = arg.type_of_export
    bucket_name = ENV["BUCKET_NAME"]
    instance_name = ENV["INSTANCE_NAME"]

    raise Boundary::ArgumentMissing, "type_of_export. You  must specify 'for_odc' or 'not_for_odc'" if type_of_export.nil? || !%w[for_odc not_for_odc].include?(type_of_export)

    raise Boundary::ArgumentMissing, "bucket_name or instance_name" unless bucket_name || instance_name

    exporter = ApiFactory.export_not_for_publication_use_case
    data = exporter.execute

    raise Boundary::OpenDataEmpty if data.length.zero?

    csv_data = Helper::ExportHelper.to_csv(data)
    OpenDataExportHelper.transmit_not_for_publication_file data: csv_data,
                                                           type_of_export: type_of_export,
                                                           env: ENV

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
