require_relative "./worker_helpers"
require_relative "./open_data_export_helper"

module Worker
  class NotForPublicationOpenDataExport
    include Sidekiq::Worker

    def perform
      Worker::OpenDataExportHelper.call_rake(rake_name: "open_data:export_not_for_publication")
    rescue Boundary::OpenDataEmpty => e
      Sentry.capture_exception(e)  if defined?(Sentry)
    end
  end
end
