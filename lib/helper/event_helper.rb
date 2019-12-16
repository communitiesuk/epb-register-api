module Helper
  class EventHelper
    def initialize
      $stdout.sync = true
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} event:#{msg}\n"
      end

    end

    def event(event_code)
      @logger.info(event_code.to_s.upcase)
    end
  end
end
