describe EventBroadcaster do
  subject(:broadcaster) { described_class.new }

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
end
