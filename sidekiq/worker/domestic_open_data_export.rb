require_relative "./worker_helpers"
require_relative "./open_data_export_helper"

module Worker
  class DomesticOpenDataExport
    include Sidekiq::Worker

    def perform
      ENV["INSTANCE_NAME"] = "mhclg-epb-s3-open-data-export"
      Worker::OpenDataExportHelper.call_rake("SAP-RDSAP")
    rescue Boundary::OpenDataEmpty => e
      Sentry.capture_exception(e)  if defined?(Sentry)
    end
  end
end
