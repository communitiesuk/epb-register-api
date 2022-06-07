describe Events::Broadcaster do
  subject(:broadcaster) { described_class.new(logger:) }

  let(:logger) { instance_spy(Logger) }

  around do |test|
    described_class.enable!
    test.run
    described_class.disable!
  end

  it "is a Wisper publisher" do
    expect(broadcaster).to be_a_kind_of Wisper::Publisher
  end

  context "when an event is broadcast", :aggregate_failures do
    before_is_triggered = false
    after_is_triggered = false

    before do
      broadcaster.on(:something_happened) { before_is_triggered = true }
      broadcaster.broadcast(:something_happened)
      broadcaster.on(:something_happened) { after_is_triggered = true }
    end

    it "fires the registered listener" do
      expect(before_is_triggered).to be true
    end

    it "does not fire a listener that has not already been registered" do
      expect(after_is_triggered).to be false
    end
  end

  context "when an event is broadcast with data" do
    event_data = []

    before do
      broadcaster.on(:something_with_data_happened) { |**data| event_data << data }
    end

    it "passes the event data through to the listener" do
      data = { entity_id: "42" }
      broadcaster.broadcast(:something_with_data_happened, **data)
      expect(event_data).to eq [data]
    end
  end

  context "when broadcasting is disabled" do
    around do |test|
      described_class.disable!
      test.run
      described_class.enable!
    end

    context "when an event is broadcast with a registered listener" do
      listener_triggered = false

      before do
        broadcaster.on(:hi_i_am_an_event) { listener_triggered = true }
        broadcaster.broadcast(:hi_i_am_an_event)
      end

      it "does not notify the listener" do
        expect(listener_triggered).to be false
      end
    end
  end

  context "when certain events are ignored" do
    let(:broadcasted) { [] }

    before do
      described_class.accept_only! :accepted_event_1, :accepted_event_2
      broadcaster.on(:accepted_event_1) { broadcasted << :accepted_event_1 }
      broadcaster.on(:accepted_event_2) { broadcasted << :accepted_event_2 }
      broadcaster.on(:ignored_event_1) { broadcasted << :ignored_event_1 }
    end

    after do
      described_class.accept_any!
    end

    it "only allows accepted events to be listened to" do
      broadcaster.broadcast :accepted_event_1
      broadcaster.broadcast :accepted_event_2
      broadcaster.broadcast :ignored_event_1
      expect(broadcasted).to match_array %i[accepted_event_1 accepted_event_2]
    end
  end

  context "when a listener leaks an error and an event is broadcast" do
    before do
      broadcaster.on(:exploding_event) { raise "the listener exploded" }
    end

    it "does not raise an error" do
      expect { broadcaster.broadcast(:exploding_event) }.not_to raise_error
    end

    it "logs out a message including raised error type and message" do
      broadcaster.broadcast(:exploding_event)
      expect(logger).to have_received(:error).with include("RuntimeError", "the listener exploded")
    end
  end
end
