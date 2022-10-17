require_relative "./worker_helpers"
require_relative "./open_data_export_helper"

module Worker
  class CommercialOpenDataExport
    include Sidekiq::Worker

    def perform
      begin
        Worker::OpenDataExportHelper.call_rake(assessment_types: "CEPC")
      rescue Boundary::OpenDataEmpty => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      end

      begin
        Worker::OpenDataExportHelper.call_rake(assessment_types: "DEC")
      rescue Boundary::OpenDataEmpty => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      end
    end
  end
end
