module Helper
  class LogHelper
    def event(event_code)
      p "#{{timestamp: Time.now.to_s, event_type: event_code}.to_json}"
    end
  end
end
