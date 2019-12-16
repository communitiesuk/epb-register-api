module Helper
  class LogHelper
    def initialize
      $stdout.sync = true
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{{timestamp: datetime}.merge(msg).to_json}\n"
      end

    end

    def event(event_code)
      @logger.info({event_type: event_code})
    end
  end
end
