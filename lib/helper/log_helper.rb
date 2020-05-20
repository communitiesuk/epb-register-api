require "ougai"

module Helper
  class LogHelper
    def initialize
      $stdout.sync = true
      @logger = Ougai::Logger.new(STDOUT)
    end

    def event(event_code, message = "No message", raw = false)
      unless ENV["SILENT_EVENTS"] == "true"
        if raw
          @logger.info(message)
        else
          @logger.info({ event_type: event_code, msg: message })
        end
      end
    end
  end
end
