require "wisper"

class EventBroadcaster
  include Wisper::Publisher

  @enabled = true

  def broadcast(event, *args)
    super if self.class.enabled?
  end

  def self.disable!
    @enabled = false
  end

  def self.enable!
    @enabled = true
  end

  def self.enabled?
    @enabled
  end
end
