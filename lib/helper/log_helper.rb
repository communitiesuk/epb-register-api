require 'ougai'

module Helper
  class LogHelper
    def initialize
      $stdout.sync = true
      @logger = Ougai::Logger.new(STDOUT)
    end

    def event(event_code, message = 'No message')
      @logger.info({ event_type: event_code, msg: message })
    end
  end
end
