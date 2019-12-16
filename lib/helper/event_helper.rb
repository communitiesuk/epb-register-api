module Helper
  class EventHelper
    def initialize
      @logger = Logger.new(STDOUT)
    end

    def event(event_code)
      @logger.info("EVENT:#{event_code.to_s.upcase}")
    end
  end
end
