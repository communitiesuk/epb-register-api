require_relative "./worker_helpers"
require_relative "./open_data_export_helper"

module Worker
  class RecommendationsOpenDataExport
    include Sidekiq::Worker

    def perform
      begin
        Worker::OpenDataExportHelper.call_rake(assessment_types: "CEPC-RR")
      rescue Boundary::OpenDataEmpty => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      end

      begin
        Worker::OpenDataExportHelper.call_rake(assessment_types: "DEC-RR")
      rescue Boundary::OpenDataEmpty => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      end

      begin
        Worker::OpenDataExportHelper.call_rake(assessment_types: "SAP-RDSAP-RR")
      rescue Boundary::OpenDataEmpty => e
        Sentry.capture_exception(e)  if defined?(Sentry)
      end
    end
  end
end
