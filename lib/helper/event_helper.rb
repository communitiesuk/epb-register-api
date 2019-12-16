module Helper
  class EventHelper
    def initialize
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} EVENT:#{msg}\n"
      end

    end

    def event(event_code)
      @logger.info(event_code.to_s.upcase)
    end
  end
end
