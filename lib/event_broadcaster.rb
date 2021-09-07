require "wisper"

# An event broadcaster object (sometimes called an "event dispatcher") allows
# an application to wire up actions to subscribe or listen to
# individual named events (usually that something domain-important has happened),
# and provides an interface for other objects to tell it to broadcast those named
# events.
#
# This means that when a secondary action is necessary on, say, the lodgement of
# an assessment, that action can be wired in to be invoked when an assessment is
# lodged without coupling the details of that action to the use case for the
# lodgement itself.
#
# This implementation uses Wisper (@see https://github.com/krisleech/wisper) but
# (unlike examples given in Wisper's docs) provides a common event publication object
# so that the wiring of events to listeners can be declared separately to the setup
# for the location (usually a use case's #execute method) of an event's broadcast.
#
# ==== Usage
#
# Instantiate the broadcaster:
#   broadcaster = EventBroadcaster.new
#
# Create a listener that is invoked for the event :my_event, then broadcast that event:
#   class HelloWorldListener
#     def my_event
#       puts "Hello, world!"
#     end
#   end
#
#   broadcaster.subscribe HelloWorldListener.new
#
#   broadcaster.broadcast :my_event
#   # => would print out "Hello, world!"
#
# Create a listener using a block for the event :my_event, then broadcast that event:
#   broadcaster.on(:my_event) { puts "Hello, world!" }
#
#   broadcaster.broadcast :my_event
#   # => would print out "Hello, world!"
#
# Pass data with a broadcast event, and consume it when listening
#
#   broadcaster.on(:my_event_with_data) { |*data_items| puts "data: #{data_items.join('; ')}"  }
#
#   broadcaster.broadcast :my_event_with_data, "this ID", "that other ID"
#   # => would print out "data: this ID; that other ID"
#
# Same using subscribed object:
#
#   class DataPrinter
#     def my_event_with_data(*data_items)
#       puts "data: #{data_items.join('; ')}"
#     end
#   end
#
#   broadcaster.subscribe DataPrinter.new
#
#   broadcaster.broadcast :my_event_with_data, "this ID", "that other ID"
#   # => would print out "data: this ID; that other ID"
#
# Using broadcaster within a use case:
#
#   class ImportantUseCase
#     def initialize(gateway:, event_broadcaster:)
#       @gateway = gateway
#       @event_broadcaster = event_broadcaster
#     end
#
#     def execute
#       @gateway.do_important_thing
#       @event_broadcaster.broadcast :important_thing_happened, "some ID"
#     end
#   end
#
#   class Printer
#     def important_thing_happened(id)
#       puts "event fired with data: #{id}"
#     end
#   end
#
#   broadcaster.subscribe(Printer.new)
#
#   # inject broadcaster into use case
#   use_case = ImportantUseCase.new(
#     gateway: SomeImportantGateway.new,
#     event_broadcaster: broadcaster,
#   )
#
#   use_case.execute
#   # => the important thing happens, and "event fired with data: some ID" is printed out
#
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
