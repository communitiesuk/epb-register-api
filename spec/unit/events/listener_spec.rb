describe Events::Listener do
  subject(:listener) { described_class.new(event_broadcaster) }

  let(:event_broadcaster) { instance_spy(Events::Broadcaster) }

  before do
    listener.attach_listeners
  end

  describe "#attach_listeners" do
    events = %i[
      assessment_lodged
      assessment_address_id_updated
      assessment_opt_out_status_changed
      green_deal_plan_added
      green_deal_plan_updated
      green_deal_plan_deleted
      assessor_added
    ]

    events.each do |event|
      it "attaches the #{event} event listener" do
        expect(event_broadcaster).to have_received(:on).with(event)
      end
    end

    it "attaches the cancelled events listeners" do
      expect(event_broadcaster).to have_received(:on).with(:assessment_cancelled, :assessment_marked_not_for_issue)
    end
  end
end
